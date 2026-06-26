import Foundation

public enum Ghostty {

    // ── Focus ─────────────────────────────────────────────────────────────────

    /// Brings the Ghostty app to the front.
    public static func focusApp() throws {
        try appleScript(#"tell application "Ghostty" to activate"#)
    }

    /// Searches all tabs in all Ghostty windows for one whose title starts with
    /// "<sessionName>:" — tmux propagates titles as "session: window". If found,
    /// selects that tab and activates the window. Returns true on success.
    @discardableResult
    public static func focusTab(session: String) throws -> Bool {
        let result = try appleScript("""
            tell application "Ghostty"
              activate
              repeat with w in every window
                repeat with t in every tab of w
                  if name of t starts with "\(session):" or name of t is "\(session)" then
                    activate window w
                    select tab t
                    return "found"
                  end if
                end repeat
              end repeat
              return "notfound"
            end tell
            """)
        return result.trimmingCharacters(in: .whitespacesAndNewlines) == "found"
    }

    // ── New tab ───────────────────────────────────────────────────────────────

    /// Opens a new Ghostty tab and attaches to the given tmux session.
    /// Unsets TMUX/TMUX_PANE before attaching so tmux treats this as a fresh
    /// client rather than a nested switch-client.
    public static func openTab(session: String) throws {
        try appleScript("""
            tell application "Ghostty"
              activate
              set newTab to new tab in front window
              delay 0.4
              set term to focused terminal of newTab
              input text "unset TMUX TMUX_PANE; exec tmux attach -t \(session)" to term
              send key "enter" to term
            end tell
            """)
    }

    // ── Internal ──────────────────────────────────────────────────────────────

    @discardableResult
    private static func appleScript(_ source: String) throws -> String {
        try Shell.run("osascript -e \(shellQuote(source))")
    }

    private static func shellQuote(_ s: String) -> String {
        "'\(s.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
