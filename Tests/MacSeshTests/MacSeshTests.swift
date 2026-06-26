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

// ── Tmux: session name sanitization ──────────────────────────────────────────

@Test func sanitizeSessionNameLowercasesAndReplacesSpaces() {
    #expect(sanitizeSessionName("My Project") == "my-project")
}

@Test func sanitizeSessionNameStripsLeadingAndTrailingHyphens() {
    #expect(sanitizeSessionName("  hello  ") == "hello")
}

@Test func sanitizeSessionNameCollapsesSeparators() {
    #expect(sanitizeSessionName("foo/bar/baz") == "foo-bar-baz")
}

// ── Tmux: output parsing ──────────────────────────────────────────────────────

@Test func parseSessionsReturnsNames() {
    let output = "yoto-club-api\nraycast-sesh\nsesh\n"
    #expect(parseSessions(output) == ["yoto-club-api", "raycast-sesh", "sesh"])
}

@Test func parseSessionsIgnoresBlankLines() {
    #expect(parseSessions("") == [])
    #expect(parseSessions("\n\n") == [])
}

@Test func parseClientsReturnsStructuredData() {
    let output = "/dev/ttys000:yoto-club-api:1750000000"
    let clients = parseClients(output)
    #expect(clients.count == 1)
    #expect(clients[0].tty == "/dev/ttys000")
    #expect(clients[0].session == "yoto-club-api")
    #expect(clients[0].activity == 1_750_000_000)
}

@Test func parseClientsHandlesMultipleClients() {
    let output = "/dev/ttys000:project-a:100\n/dev/ttys001:project-b:200"
    #expect(parseClients(output).count == 2)
}

@Test func parseClientsReturnsEmptyForNoOutput() {
    #expect(parseClients("") == [])
}

// ── Tmux: client selection ────────────────────────────────────────────────────

@Test func mostRecentClientReturnsNilForEmpty() {
    #expect(mostRecentClient(from: []) == nil)
}

@Test func mostRecentClientReturnsSingleClient() {
    let client = TmuxClient(tty: "/dev/ttys000", session: "foo", activity: 1)
    #expect(mostRecentClient(from: [client]) == client)
}

@Test func mostRecentClientPicksHighestActivity() {
    let older = TmuxClient(tty: "/dev/ttys000", session: "old", activity: 100)
    let newer = TmuxClient(tty: "/dev/ttys001", session: "new", activity: 200)
    #expect(mostRecentClient(from: [older, newer]) == newer)
}
