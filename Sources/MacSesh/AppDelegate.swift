import AppKit
import Carbon.HIToolbox

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var searchWindow: SearchWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHotkeys()
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "mac-sesh")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Switch Session  \u{2726}W", action: #selector(openSwitchSession), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Replace Session  \u{2726}E", action: #selector(openReplaceSession), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit mac-sesh", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    // MARK: - Global hotkeys (Carbon — no permission prompt required)

    private func setupHotkeys() {
        // Hyper key = Cmd+Ctrl+Option+Shift (Caps Lock remapped via Karabiner or similar)
        let hyper = cmdKey | controlKey | optionKey | shiftKey  // = 6912

        registerGlobalHotkey(keyCode: Int(kVK_ANSI_W), modifiers: hyper) { [weak self] in
            Task { @MainActor [weak self] in self?.openSwitchSession() }
        }
        registerGlobalHotkey(keyCode: Int(kVK_ANSI_E), modifiers: hyper) { [weak self] in
            Task { @MainActor [weak self] in self?.openReplaceSession() }
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
