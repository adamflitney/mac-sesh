import AppKit
import Carbon.HIToolbox
import MacSeshCore
import ServiceManagement

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
        statusItem?.button?.image = makeMenuBarImage()

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Switch Session  \u{2726}W", action: #selector(openSwitchSession), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Replace Session  \u{2726}E", action: #selector(openReplaceSession), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Edit Config", action: #selector(editConfig), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Reload Config", action: #selector(reloadConfig), keyEquivalent: "r"))
        menu.addItem(.separator())
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.tag = 100
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLoginItem)
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

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            NSLog("Launch at Login toggle failed: \(error)")
        }
        if let item = statusItem?.menu?.item(withTag: 100) {
            item.state = service.status == .enabled ? .on : .off
        }
    }

    @objc private func reloadConfig() {
        unregisterAllHotkeys()
        config = Config.load()
        setupHotkeys()
        // Dismiss any open search window so it picks up the new config on next open
        searchWindow?.orderOut(nil)
    }

    private func makeMenuBarImage() -> NSImage {
        let s: CGFloat = 18
        let image = NSImage(size: NSSize(width: s, height: s), flipped: false) { _ in
            let sectionGap = s * 0.04
            let colBar = s * 0.16
            let rowBar = s * 0.10
            let colGapY = s * 0.035
            let barRadius = colBar * 0.14
            let totalBarSpan = colBar * 3 + s * 0.06 * 2
            let colGapX = (totalBarSpan - colBar * 3) / 2
            let sectionH = rowBar * 3 + colGapY * 2
            let startX = (s - totalBarSpan) / 2
            let startY = (s - (sectionH * 2 + sectionGap)) / 2

            NSColor.black.setFill()

            for j in 0..<3 {
                let y = startY + CGFloat(j) * (rowBar + colGapY)
                NSBezierPath(roundedRect: NSRect(x: startX, y: y, width: totalBarSpan, height: rowBar),
                             xRadius: barRadius, yRadius: barRadius).fill()
            }

            let mStartY = startY + sectionH + sectionGap
            for i in 0..<3 {
                let x = startX + CGFloat(i) * (colBar + colGapX)
                NSBezierPath(roundedRect: NSRect(x: x, y: mStartY, width: colBar, height: sectionH),
                             xRadius: barRadius, yRadius: barRadius).fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    private func showSearch(mode: SearchMode) {
        if searchWindow == nil {
            searchWindow = SearchWindow()
        }
        searchWindow?.present(mode: mode, config: config)
    }
}
