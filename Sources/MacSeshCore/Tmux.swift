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

public func createSession(name: String, path: String) throws {
    let s = shellQuote(name)
    let p = shellQuote(path)
    try Shell.run("tmux new-session -d -s \(s) -c \(p) -n neovim")
    try Shell.run("tmux send-keys -t \(shellQuote("\(name):neovim")) 'nvim .' Enter")
    try Shell.run("tmux new-window -t \(s) -n claude -c \(p)")
    try Shell.run("tmux send-keys -t \(shellQuote("\(name):claude")) 'claude' Enter")
    try Shell.run("tmux new-window -t \(s) -n shell -c \(p)")
    try Shell.run("tmux select-window -t \(shellQuote("\(name):neovim"))")
}

/// Adds any missing windows from the standard 3-window layout without
/// touching windows the user has already set up.
public func ensureSessionWindows(name: String, path: String) throws {
    let existing = Set(try listWindows(session: name))
    let s = shellQuote(name)
    let p = shellQuote(path)

    if !existing.contains("neovim") {
        try Shell.run("tmux new-window -t \(s) -n neovim -c \(p)")
        try Shell.run("tmux send-keys -t \(shellQuote("\(name):neovim")) 'nvim .' Enter")
    }
    if !existing.contains("claude") {
        try Shell.run("tmux new-window -t \(s) -n claude -c \(p)")
        try Shell.run("tmux send-keys -t \(shellQuote("\(name):claude")) 'claude' Enter")
    }
    if !existing.contains("shell") {
        try Shell.run("tmux new-window -t \(s) -n shell -c \(p)")
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
