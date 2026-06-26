import Foundation
@testable import MacSeshCore

nonisolated(unsafe) var failures = 0

func test(_ name: String, _ body: () throws -> Void) {
    do {
        try body()
        print("✓ \(name)")
    } catch {
        print("✗ \(name): \(error)")
        failures += 1
    }
}

func expect<T: Equatable>(_ actual: T, equals expected: T) throws {
    if actual != expected {
        throw Fail("expected \(expected), got \(actual)")
    }
}

struct Fail: Error, CustomStringConvertible {
    let description: String
    init(_ d: String) { description = d }
}

// ── Shell ─────────────────────────────────────────────────────────────────────

test("Shell.run returns stdout trimmed") {
    let out = try Shell.run("echo hello")
    try expect(out, equals: "hello")
}

test("Shell.run throws on non-zero exit") {
    var threw = false
    do {
        _ = try Shell.run("false")
    } catch {
        threw = true
    }
    try expect(threw, equals: true)
}

// ── Tmux ──────────────────────────────────────────────────────────────────────

test("sanitizeSessionName lowercases and replaces spaces") {
    try expect(sanitizeSessionName("My Project"), equals: "my-project")
}

test("sanitizeSessionName strips leading and trailing hyphens") {
    try expect(sanitizeSessionName("  hello  "), equals: "hello")
}

test("sanitizeSessionName collapses multiple separators") {
    try expect(sanitizeSessionName("foo/bar/baz"), equals: "foo-bar-baz")
}

// ── Run ───────────────────────────────────────────────────────────────────────

print(failures == 0 ? "\nAll tests passed." : "\n\(failures) test(s) failed.")
exit(failures > 0 ? 1 : 0)
