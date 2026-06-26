import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var searchWindow: SearchWindow?
    private var hotkeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        requestAccessibilityAndRegisterHotkeys()
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "mac-sesh")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Switch Session  ⌘⇧S", action: #selector(openSwitchSession), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Replace Session  ⌘⇧R", action: #selector(openReplaceSession), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit mac-sesh", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    // MARK: - Global hotkeys

    private func requestAccessibilityAndRegisterHotkeys() {
        // NSEvent global monitors require Accessibility permission.
        // AXIsProcessTrustedWithOptions prompts on first launch.
        if !AXIsProcessTrusted() {
            // Use the raw string key to avoid Swift 6 concurrency issues with the C global
            let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            AXIsProcessTrustedWithOptions(opts)
        }

        hotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.intersection([.command, .shift, .option, .control]) == [.command, .shift] else { return }
            switch Int(event.keyCode) {
            case 1:  // S
                Task { @MainActor [weak self] in self?.openSwitchSession() }
            case 15: // R
                Task { @MainActor [weak self] in self?.openReplaceSession() }
            default:
                break
            }
        }
    }

    // MARK: - Actions

    @objc func openSwitchSession() {
        showSearch(mode: .switchSession)
    }

    @objc func openReplaceSession() {
        showSearch(mode: .replaceSession)
    }

    private func showSearch(mode: SearchMode) {
        if searchWindow == nil {
            searchWindow = SearchWindow()
        }
        searchWindow?.present(mode: mode)
    }
}
