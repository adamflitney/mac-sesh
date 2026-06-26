import Foundation

// Test runner for use without Xcode (swift run MacSeshTests).
// Each test() call prints ✓ or ✗ and exits 1 if anything fails.
//
// nonisolated(unsafe) opts the counter out of Swift 6's actor isolation —
// safe here because the tests run single-threaded on the main thread.

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

// ── Smoke test ────────────────────────────────────────────────────────────────

test("runner works") {
    try expect(1 + 1, equals: 2)
}

// ── Run ───────────────────────────────────────────────────────────────────────

print(failures == 0 ? "\nAll tests passed." : "\n\(failures) test(s) failed.")
exit(failures > 0 ? 1 : 0)
