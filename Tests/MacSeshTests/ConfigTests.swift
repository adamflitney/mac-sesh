import Testing
import Foundation
@testable import MacSeshCore

// MARK: - Hotkey parsing

@Test func parseHotkeyHyperLetter() {
    let result = parseHotkey("hyper+w")
    #expect(result?.keyCode == 13)        // kVK_ANSI_W
    #expect(result?.modifiers == 6912)    // cmd|ctrl|opt|shift
}

@Test func parseHotkeyMultipleModifiers() {
    let result = parseHotkey("cmd+shift+s")
    #expect(result?.keyCode == 1)         // kVK_ANSI_S
    #expect(result?.modifiers == 256 | 512)
}

@Test func parseHotkeyOrderIndependent() {
    let a = parseHotkey("cmd+shift+k")
    let b = parseHotkey("shift+cmd+k")
    #expect(a?.keyCode == b?.keyCode)
    #expect(a?.modifiers == b?.modifiers)
}

@Test func parseHotkeyUnknownKeyReturnsNil() {
    #expect(parseHotkey("hyper+@") == nil)
}

@Test func parseHotkeyMissingKeyReturnsNil() {
    #expect(parseHotkey("cmd+shift") == nil)
}

@Test func parseHotkeyFunctionKey() {
    let result = parseHotkey("hyper+f1")
    #expect(result?.keyCode == 122)
    #expect(result?.modifiers == 6912)
}

// MARK: - Default config

@Test func defaultConfigHasExpectedHotkeys() {
    #expect(Config.default.hotkeys.switchSession == "hyper+w")
    #expect(Config.default.hotkeys.replaceSession == "hyper+e")
}

@Test func defaultConfigHasThreeWindows() {
    #expect(Config.default.session.windows.count == 3)
}

@Test func defaultConfigFirstWindowIsNeovim() {
    #expect(Config.default.session.windows.first?.name == "neovim")
}

// MARK: - Round-trip serialisation

@Test func configRoundTrip() throws {
    let original = Config.default
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Config.self, from: data)
    #expect(decoded == original)
}

// MARK: - Exclude filter

@Test func isExcludedMatchesPrefix() {
    var cfg = Config.default
    cfg.projects.exclude = ["/Users/adam/dev/archived"]
    #expect(cfg.isExcluded("/Users/adam/dev/archived/old-project"))
    #expect(!cfg.isExcluded("/Users/adam/dev/active-project"))
}

@Test func isExcludedExpandsTilde() {
    var cfg = Config.default
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    cfg.projects.exclude = ["~/dev/archived"]
    #expect(cfg.isExcluded("\(home)/dev/archived/old-project"))
    #expect(!cfg.isExcluded("\(home)/dev/active"))
}
