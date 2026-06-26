import AppKit
import SwiftUI
import MacSeshCore

@MainActor
final class SearchWindow: NSPanel {

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .none
    }

    // NSPanel with .borderless won't become key by default; override to allow
    // keyboard input in the hosted SwiftUI view.
    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        orderOut(nil)
    }

    func present(mode: SearchMode, config: Config) {
        let view = SearchView(mode: mode, config: config, onDismiss: { [weak self] in
            self?.orderOut(nil)
        })
        contentViewController = NSHostingController(rootView: view)
        center()
        // Always position on the primary display (screens.first = the one with the menu bar),
        // not whichever screen happens to have the focused window right now.
        if let screen = NSScreen.screens.first {
            let sf = screen.visibleFrame
            let x = sf.midX - frame.width / 2
            let y = sf.midY + 60
            setFrameOrigin(NSPoint(x: x, y: y))
        }
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
