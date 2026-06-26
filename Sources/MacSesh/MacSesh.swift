import AppKit

@main
struct MacSeshApp {
    static func main() {
        // @main entry is always called on the main thread; MainActor.assumeIsolated
        // lets us call @MainActor-isolated AppKit APIs without an async context.
        MainActor.assumeIsolated {
            let app = NSApplication.shared
            app.setActivationPolicy(.accessory)
            let delegate = AppDelegate()
            app.delegate = delegate
            app.run()
        }
    }
}
