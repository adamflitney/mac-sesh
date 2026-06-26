import Testing
@testable import MacSeshCore

@Test func fuzzyScoreMatchesExactString() {
    #expect(fuzzyScore("club", in: "club") != nil)
}

@Test func fuzzyScoreMatchesSubstring() {
    #expect(fuzzyScore("club", in: "yoto-club-api") != nil)
}

@Test func fuzzyScoreMatchesFuzzyChars() {
    #expect(fuzzyScore("yca", in: "yoto-club-api") != nil)
}

@Test func fuzzyScoreReturnsNilWhenCharsOutOfOrder() {
    #expect(fuzzyScore("bca", in: "abc") == nil)
}

@Test func fuzzyScoreReturnsNilForNoMatch() {
    #expect(fuzzyScore("xyz", in: "yoto-club-api") == nil)
}

@Test func fuzzyScoreExactMatchOutranksSubstringMatch() {
    let exact   = fuzzyScore("club", in: "club")!
    let partial = fuzzyScore("club", in: "yoto-club-api")!
    #expect(exact > partial)
}

@Test func fuzzyScoreShorterCandidateOutranksLonger() {
    // "club" matches both; yoto-club-api is shorter so denser → ranks higher
    let shorter = fuzzyScore("club", in: "yoto-club-api")!
    let longer  = fuzzyScore("club", in: "yoto-club-notifications")!
    #expect(shorter > longer)
}

@Test func fuzzyScoreConsecutiveRunOutranksScatteredChars() {
    // "api" matches as a consecutive run in yoto-club-api vs scattered in "a-project-inc"
    let consecutive = fuzzyScore("api", in: "yoto-club-api")!
    let scattered   = fuzzyScore("api", in: "a-project-inc")!
    #expect(consecutive > scattered)
}

@Test func fuzzyScoreEmptyQueryAlwaysMatches() {
    #expect(fuzzyScore("", in: "anything") != nil)
}
