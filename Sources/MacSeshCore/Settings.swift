import Foundation

public enum Settings {
    private static let directoriesKey = "MacSesh.projectDirectories"

    public static var projectDirectories: [String] {
        get {
            let stored = UserDefaults.standard.stringArray(forKey: directoriesKey)
            if let stored, !stored.isEmpty { return stored }
            // Default to ~/dev so the app works without any configuration
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            return ["\(home)/dev"]
        }
        set { UserDefaults.standard.set(newValue, forKey: directoriesKey) }
    }
}
