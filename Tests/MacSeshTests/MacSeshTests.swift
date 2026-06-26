import Testing
@testable import MacSeshCore

// ── Shell ─────────────────────────────────────────────────────────────────────

@Test func shellRunReturnsTrimmedOutput() throws {
    let out = try Shell.run("echo hello")
    #expect(out == "hello")
}

@Test func shellRunThrowsOnNonZeroExit() throws {
    #expect(throws: (any Error).self) {
        try Shell.run("false")
    }
}

// ── Tmux ──────────────────────────────────────────────────────────────────────

@Test func sanitizeSessionNameLowercasesAndReplacesSpaces() {
    #expect(sanitizeSessionName("My Project") == "my-project")
}

@Test func sanitizeSessionNameStripsLeadingAndTrailingHyphens() {
    #expect(sanitizeSessionName("  hello  ") == "hello")
}

@Test func sanitizeSessionNameCollapsesSeparators() {
    #expect(sanitizeSessionName("foo/bar/baz") == "foo-bar-baz")
}
