import AppKit
import SwiftUI

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
    }

    // NSPanel with .borderless won't become key by default; override to allow
    // keyboard input in the hosted SwiftUI view.
    override var canBecomeKey: Bool { true }

    override func resignKey() {
        super.resignKey()
        orderOut(nil)
    }

    func present(mode: SearchMode) {
        let view = SearchView(mode: mode, onDismiss: { [weak self] in
            self?.orderOut(nil)
        })
        contentViewController = NSHostingController(rootView: view)
        center()
        // Nudge the window above center — Raycast-style placement
        if let screen = NSScreen.main {
            let y = screen.visibleFrame.midY + 60
            setFrameOrigin(NSPoint(x: frame.minX, y: y))
        }
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
