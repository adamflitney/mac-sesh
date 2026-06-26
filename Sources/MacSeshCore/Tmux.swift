import Foundation

// ── Types ─────────────────────────────────────────────────────────────────────

public struct TmuxClient: Equatable {
    public let tty: String
    public let session: String
    public let activity: Int
}

// ── Parsing ───────────────────────────────────────────────────────────────────

public func parseSessions(_ output: String) -> [String] {
    output.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
}

public func parseClients(_ output: String) -> [TmuxClient] {
    output.split(separator: "\n").compactMap { line in
        let parts = line.split(separator: ":", maxSplits: 2).map(String.init)
        guard parts.count == 3 else { return nil }
        return TmuxClient(
            tty: parts[0],
            session: parts[1],
            activity: Int(parts[2]) ?? 0
        )
    }
}

public func mostRecentClient(from clients: [TmuxClient]) -> TmuxClient? {
    clients.max(by: { $0.activity < $1.activity })
}

// ── Session name ──────────────────────────────────────────────────────────────

public func sanitizeSessionName(_ name: String) -> String {
    var s = name
        .trimmingCharacters(in: .whitespaces)
        .lowercased()
        .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
    while s.hasPrefix("-") { s = String(s.dropFirst()) }
    while s.hasSuffix("-") { s = String(s.dropLast()) }
    return s
}

// ── Shell commands ────────────────────────────────────────────────────────────

public func listSessions() throws -> [String] {
    let output = try Shell.run("tmux list-sessions -F '#{session_name}'")
    return parseSessions(output)
}

public func listClients() throws -> [TmuxClient] {
    let output = try Shell.run("tmux list-clients -F '#{client_tty}:#{client_session}:#{client_activity}'")
    return parseClients(output)
}

/// Creates a new detached tmux session with windows defined by `windows`.
/// The first window is created via `new-session`; subsequent ones via `new-window`.
/// Focus is left on `defaultWindow` (or the first window if nil).
public func createSession(name: String, path: String, windows: [WindowSpec], defaultWindow: String? = nil) throws {
    guard let first = windows.first else { return }
    let s = shellQuote(name)
    let p = shellQuote(path)

    try Shell.run("tmux new-session -d -s \(s) -c \(p) -n \(shellQuote(first.name))")
    if let cmd = first.command {
        try Shell.run("tmux send-keys -t \(shellQuote("\(name):\(first.name)")) \(shellQuote(cmd)) Enter")
    }

    for spec in windows.dropFirst() {
        try Shell.run("tmux new-window -t \(s) -n \(shellQuote(spec.name)) -c \(p)")
        if let cmd = spec.command {
            try Shell.run("tmux send-keys -t \(shellQuote("\(name):\(spec.name)")) \(shellQuote(cmd)) Enter")
        }
    }

    let focusWindow = defaultWindow ?? first.name
    try Shell.run("tmux select-window -t \(shellQuote("\(name):\(focusWindow)"))")
}

/// Adds any missing windows from `windows` without touching existing ones.
public func ensureSessionWindows(name: String, path: String, windows: [WindowSpec]) throws {
    let existing = Set(try listWindows(session: name))
    let s = shellQuote(name)
    let p = shellQuote(path)

    for spec in windows where !existing.contains(spec.name) {
        try Shell.run("tmux new-window -t \(s) -n \(shellQuote(spec.name)) -c \(p)")
        if let cmd = spec.command {
            try Shell.run("tmux send-keys -t \(shellQuote("\(name):\(spec.name)")) \(shellQuote(cmd)) Enter")
        }
    }
}

public func switchClient(session: String, tty: String) throws {
    try Shell.run("tmux switch-client -t \(shellQuote(session)) -c \(shellQuote(tty))")
}

public func listWindows(session: String) throws -> [String] {
    let output = try Shell.run("tmux list-windows -t \(shellQuote(session)) -F \"#{window_name}\"")
    return parseSessions(output)
}

// ── Helpers ───────────────────────────────────────────────────────────────────

private func shellQuote(_ s: String) -> String {
    "'\(s.replacingOccurrences(of: "'", with: "'\\''"))'"
}
