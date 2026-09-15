import Foundation
import Testing

@testable import FlashcardKit

@Suite("Three-choice session validation")
struct ThreeChoiceSessionValidationTests {
    @Test("At least three cards are required")
    func insufficientCards() throws {
        let cards = try [card(1, "one"), card(2, "two")]

        #expect(throws: ThreeChoiceSessionError.insufficientCards(minimum: 3, actual: 2)) {
            try ThreeChoiceSession(
                cards: cards,
                configuration: ThreeChoiceSessionConfiguration(seed: 1)
            )
        }
    }

    @Test("At least three distinct visible answers are required")
    func insufficientDistinctAnswers() throws {
        let cards = try [card(1, "same"), card(2, "same"), card(3, "other")]

        #expect(
            throws: ThreeChoiceSessionError.insufficientDistinctAnswers(minimum: 3, actual: 2)
        ) {
            try ThreeChoiceSession(
                cards: cards,
                configuration: ThreeChoiceSessionConfiguration(seed: 1)
            )
        }
    }

    @Test("Card identities must be unique")
    func duplicateCardIdentity() throws {
        let cards = try [card(1, "one"), card(1, "two"), card(3, "three")]

        #expect(throws: ThreeChoiceSessionError.duplicateCardID(cardID(1))) {
            try ThreeChoiceSession(
                cards: cards,
                configuration: ThreeChoiceSessionConfiguration(seed: 1)
            )
        }
    }

    @Test(
        "Round count must fit the source cards",
        arguments: [
            RoundCountExample(
                roundCount: 0,
                error: .invalidRoundCount(0)
            ),
            RoundCountExample(
                roundCount: -1,
                error: .invalidRoundCount(-1)
            ),
            RoundCountExample(
                roundCount: 4,
                error: .roundCountExceedsAvailableCards(requested: 4, available: 3)
            ),
        ]
    )
    func invalidRoundCount(example: RoundCountExample) throws {
        let cards = try [card(1, "one"), card(2, "two"), card(3, "three")]

        #expect(throws: example.error) {
            try ThreeChoiceSession(
                cards: cards,
                configuration: ThreeChoiceSessionConfiguration(
                    seed: 1,
                    roundCount: example.roundCount
                )
            )
        }
    }

    private func card(_ id: Int, _ answer: String) throws -> Flashcard {
        Flashcard(
            id: cardID(id),
            prompt: try FlashcardContent(text: "prompt-\(id)"),
            answer: try FlashcardContent(text: answer)
        )
    }

    private func cardID(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}

extension ThreeChoiceSessionValidationTests {
    struct RoundCountExample: Sendable, CustomTestStringConvertible {
        let roundCount: Int
        let error: ThreeChoiceSessionError

        var testDescription: String { "roundCount=\(roundCount)" }
    }
}
