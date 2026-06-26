import Foundation

enum Shell {
    /// Runs a shell command and returns trimmed stdout.
    /// Throws if the process exits with a non-zero status.
    static func run(_ command: String) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = Pipe()  // suppress stderr
        process.environment = cleanEnv()

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw ShellError.nonZeroExit(Int(process.terminationStatus), command)
        }

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Strips TMUX/TMUX_PANE so nested-tmux issues don't affect shell commands,
    // and ensures Homebrew paths are available.
    private static func cleanEnv() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env.removeValue(forKey: "TMUX")
        env.removeValue(forKey: "TMUX_PANE")
        let extra = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        env["PATH"] = "\(extra):\(env["PATH"] ?? "")"
        return env
    }
}

enum ShellError: Error, CustomStringConvertible {
    case nonZeroExit(Int, String)

    var description: String {
        switch self {
        case .nonZeroExit(let code, let cmd):
            return "Command exited \(code): \(cmd)"
        }
    }
}
