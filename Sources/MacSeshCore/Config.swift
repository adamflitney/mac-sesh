import Foundation

// MARK: - Types

public struct Config: Codable, Equatable, Sendable {
    public var hotkeys: HotkeyConfig
    public var session: SessionConfig
    public var projects: ProjectsConfig

    public init(hotkeys: HotkeyConfig, session: SessionConfig, projects: ProjectsConfig) {
        self.hotkeys = hotkeys
        self.session = session
        self.projects = projects
    }

    public static let `default` = Config(
        hotkeys: HotkeyConfig(switchSession: "hyper+w", replaceSession: "hyper+e"),
        session: SessionConfig(
            windows: [
                WindowSpec(name: "neovim",  command: "nvim ."),
                WindowSpec(name: "claude",  command: "claude"),
                WindowSpec(name: "shell",   command: nil),
            ],
            defaultWindow: "neovim"
        ),
        projects: ProjectsConfig(
            directories: ["~/dev"],
            exclude: []
        )
    )
}

public struct HotkeyConfig: Codable, Equatable, Sendable {
    public var switchSession: String
    public var replaceSession: String

    public init(switchSession: String, replaceSession: String) {
        self.switchSession = switchSession
        self.replaceSession = replaceSession
    }
}

public struct SessionConfig: Codable, Equatable, Sendable {
    public var windows: [WindowSpec]
    /// Name of the window to focus after session creation. Defaults to the first window.
    public var defaultWindow: String?

    public init(windows: [WindowSpec], defaultWindow: String? = nil) {
        self.windows = windows
        self.defaultWindow = defaultWindow
    }
}

public struct WindowSpec: Codable, Equatable, Sendable {
    public let name: String
    /// Shell command to run on window open. nil = plain shell in the project directory.
    public let command: String?

    public init(name: String, command: String? = nil) {
        self.name = name
        self.command = command
    }
}

public struct ProjectsConfig: Codable, Equatable, Sendable {
    /// Root directories to scan for git projects.
    public var directories: [String]
    /// Paths to exclude. Prefix-matched after tilde expansion.
    public var exclude: [String]

    public init(directories: [String], exclude: [String]) {
        self.directories = directories
        self.exclude = exclude
    }
}

// MARK: - Hotkey parsing

// Carbon modifier values as raw integers — no Carbon import needed here.
private let modifierMap: [String: Int] = [
    "cmd":      256,
    "command":  256,
    "shift":    512,
    "opt":      2048,
    "option":   2048,
    "alt":      2048,
    "ctrl":     4096,
    "control":  4096,
    // Hyper = Cmd+Ctrl+Option+Shift (Caps Lock remap)
    "hyper":    256 | 512 | 2048 | 4096,
]

// Carbon virtual key codes for printable keys and a small set of specials.
private let keyCodeMap: [String: Int] = [
    "a": 0,  "s": 1,  "d": 2,  "f": 3,  "h": 4,  "g": 5,
    "z": 6,  "x": 7,  "c": 8,  "v": 9,  "b": 11, "q": 12,
    "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
    "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23,
    "9": 25, "7": 26, "8": 28, "0": 29,
    "o": 31, "u": 32, "i": 34, "p": 35, "l": 37,
    "j": 38, "k": 40, "n": 45, "m": 46,
    "space": 49, "tab": 48, "return": 36, "escape": 53, "delete": 51,
    "f1": 122, "f2": 120, "f3": 99,  "f4": 118,
    "f5": 96,  "f6": 97,  "f7": 98,  "f8": 100,
    "f9": 101, "f10": 109, "f11": 103, "f12": 111,
]

/// Parses a hotkey string like `"hyper+w"` or `"cmd+shift+k"` into a
/// `(keyCode, modifiers)` pair suitable for Carbon `RegisterEventHotKey`.
/// Returns nil if the string is malformed or uses an unrecognised key name.
public func parseHotkey(_ string: String) -> (keyCode: Int, modifiers: Int)? {
    let parts = string.lowercased().split(separator: "+").map(String.init)
    var modifiers = 0
    var keyName: String?

    for part in parts {
        if let mod = modifierMap[part] {
            modifiers |= mod
        } else if keyCodeMap[part] != nil {
            keyName = part
        } else {
            return nil  // unrecognised token
        }
    }

    guard let keyName, let keyCode = keyCodeMap[keyName] else { return nil }
    return (keyCode: keyCode, modifiers: modifiers)
}

// MARK: - Load / save

public extension Config {
    static var configURL: URL {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/mac-sesh")
        return configDir.appendingPathComponent("config.json")
    }

    /// Loads the config from disk. Falls back to `.default` on any error and
    /// writes the default file so the user has a template to edit.
    static func load() -> Config {
        let url = configURL
        guard let data = try? Data(contentsOf: url) else {
            (try? Config.default.save())   // write template on first launch
            return .default
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode(Config.self, from: data)) ?? .default
    }

    func save() throws {
        let url = Config.configURL
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: url, options: .atomic)
    }
}

// MARK: - Project directory helpers

public extension Config {
    /// Resolves tilde in paths and returns the expanded include directories.
    var resolvedDirectories: [String] {
        projects.directories.map(expandTilde)
    }

    /// Returns true if the given project path should be excluded.
    func isExcluded(_ path: String) -> Bool {
        projects.exclude
            .map(expandTilde)
            .contains { path.hasPrefix($0) }
    }
}

private func expandTilde(_ path: String) -> String {
    guard path.hasPrefix("~") else { return path }
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    return home + path.dropFirst()
}
