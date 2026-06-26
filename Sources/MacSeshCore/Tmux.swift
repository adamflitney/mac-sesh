import Foundation

/// Converts a project name into a valid tmux session name:
/// lowercase, alphanumeric + hyphens only, no leading/trailing hyphens.
func sanitizeSessionName(_ name: String) -> String {
    var s = name
        .trimmingCharacters(in: .whitespaces)
        .lowercased()
        .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
    // Strip leading/trailing hyphens that may result from the replacement
    while s.hasPrefix("-") { s = String(s.dropFirst()) }
    while s.hasSuffix("-") { s = String(s.dropLast()) }
    return s
}
