import AppKit
import Carbon.HIToolbox
import MacSeshCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var searchWindow: SearchWindow?
    private(set) var config = Config.load()

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
        menu.addItem(NSMenuItem(title: "Edit Config", action: #selector(editConfig), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Reload Config", action: #selector(reloadConfig), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit mac-sesh", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    // MARK: - Hotkeys

    private func setupHotkeys() {
        if let hk = parseHotkey(config.hotkeys.switchSession) {
            registerGlobalHotkey(keyCode: hk.keyCode, modifiers: hk.modifiers) { [weak self] in
                Task { @MainActor [weak self] in self?.openSwitchSession() }
            }
        }
        if let hk = parseHotkey(config.hotkeys.replaceSession) {
            registerGlobalHotkey(keyCode: hk.keyCode, modifiers: hk.modifiers) { [weak self] in
                Task { @MainActor [weak self] in self?.openReplaceSession() }
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

    @objc private func editConfig() {
        // Write the file if it doesn't exist yet, then open in default editor
        try? config.save()
        NSWorkspace.shared.open(Config.configURL)
    }

    @objc private func reloadConfig() {
        unregisterAllHotkeys()
        config = Config.load()
        setupHotkeys()
        // Dismiss any open search window so it picks up the new config on next open
        searchWindow?.orderOut(nil)
    }

    private func showSearch(mode: SearchMode) {
        if searchWindow == nil {
            searchWindow = SearchWindow()
        }
        searchWindow?.present(mode: mode, config: config)
    }
}
