import Testing

@testable import FlashcardKit

@Suite("Flashcard logging")
struct FlashcardLoggingTests {
    @Test("Messages use the package identity and expose no card content")
    func packageIdentity() {
        #expect(FlashcardLogging.subsystem == "com.thatfactory.flashcardkit")
        #expect(FlashcardLogging.formatted("session created | rounds=3") == "🃏 session created | rounds=3")
    }

    @Test(
        "Evaluation outcomes have stable privacy-safe tokens",
        arguments: [
            OutcomeToken(outcome: .correct, token: "correct"),
            OutcomeToken(outcome: .incorrect, token: "incorrect"),
            OutcomeToken(outcome: .expired, token: "expired"),
        ]
    )
    func outcomeTokens(example: OutcomeToken) {
        #expect(example.outcome.token == example.token)
    }
}

extension FlashcardLoggingTests {
    struct OutcomeToken: Sendable, CustomTestStringConvertible {
        let outcome: ThreeChoiceEvaluation.Outcome
        let token: String

        var testDescription: String { token }
    }
}
