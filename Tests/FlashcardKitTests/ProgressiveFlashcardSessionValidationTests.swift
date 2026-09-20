import Testing

@testable import FlashcardKit

@Suite("Progressive flashcard session validation")
struct ProgressiveFlashcardSessionValidationTests {
    @Test(
        "Card count must be positive",
        arguments: [0, -1]
    )
    func invalidCardCount(cardCount: Int) throws {
        #expect(throws: ProgressiveFlashcardSessionError.invalidCardCount(cardCount)) {
            try ProgressiveFlashcardSession(
                cards: [ProgressiveFlashcardTestFixtures.card(1)],
                configuration: ProgressiveFlashcardSessionConfiguration(
                    seed: 1,
                    cardCount: cardCount
                )
            )
        }
    }

    @Test("Card count cannot exceed the source collection")
    func excessiveCardCount() throws {
        #expect(
            throws: ProgressiveFlashcardSessionError.cardCountExceedsAvailableCards(
                requested: 2,
                available: 1
            )
        ) {
            try ProgressiveFlashcardSession(
                cards: [ProgressiveFlashcardTestFixtures.card(1)],
                configuration: ProgressiveFlashcardSessionConfiguration(seed: 1, cardCount: 2)
            )
        }
    }

    @Test("Source card identities must be unique before selection")
    func duplicateCardIDs() throws {
        let card = try ProgressiveFlashcardTestFixtures.card(1)

        #expect(throws: ProgressiveFlashcardSessionError.duplicateCardID(card.id)) {
            try ProgressiveFlashcardSession(
                cards: [card, card],
                configuration: ProgressiveFlashcardSessionConfiguration(seed: 1, cardCount: 1)
            )
        }
    }

    @Test("One selected card is valid")
    func oneCardSession() throws {
        let session = try ProgressiveFlashcardSession(
            cards: [ProgressiveFlashcardTestFixtures.card(1)],
            configuration: ProgressiveFlashcardSessionConfiguration(seed: 1, cardCount: 1)
        )

        #expect(session.currentAttempt?.id == 0)
        #expect(session.currentAttempt?.stageIndex == 0)
        #expect(session.progress.generatedAttempts == 1)
    }

    @Test("Stale attempts fail without mutation")
    func staleAttempt() throws {
        var session = try ProgressiveFlashcardSession(
            cards: [ProgressiveFlashcardTestFixtures.card(1)],
            configuration: ProgressiveFlashcardSessionConfiguration(seed: 1, cardCount: 1)
        )
        let first = try #require(session.currentAttempt)
        _ = try session.submit(.expired, forAttemptID: first.id)
        let current = session.currentAttempt
        let progress = session.progress

        #expect(throws: ProgressiveFlashcardSessionError.staleAttempt(expected: 1, received: 0)) {
            try session.submit(.correct, forAttemptID: first.id)
        }

        #expect(session.currentAttempt == current)
        #expect(session.progress == progress)
    }

    @Test(arguments: [-1, 1])
    func invalidAttemptsFailWithoutMutation(attemptID: Int) throws {
        var session = try ProgressiveFlashcardSession(
            cards: [ProgressiveFlashcardTestFixtures.card(1)],
            configuration: ProgressiveFlashcardSessionConfiguration(seed: 1, cardCount: 1)
        )
        let current = session.currentAttempt
        let progress = session.progress

        #expect(throws: ProgressiveFlashcardSessionError.invalidAttempt(attemptID)) {
            try session.submit(.correct, forAttemptID: attemptID)
        }

        #expect(session.currentAttempt == current)
        #expect(session.progress == progress)
    }

    @Test("Submission after completion fails without mutation")
    func submissionAfterCompletion() throws {
        var session = try ProgressiveFlashcardSession(
            cards: [ProgressiveFlashcardTestFixtures.card(1, stageCount: 1)],
            configuration: ProgressiveFlashcardSessionConfiguration(seed: 1, cardCount: 1)
        )
        let attempt = try #require(session.currentAttempt)
        _ = try session.submit(.correct, forAttemptID: attempt.id)
        let progress = session.progress

        #expect(throws: ProgressiveFlashcardSessionError.sessionComplete) {
            try session.submit(.correct, forAttemptID: attempt.id)
        }

        #expect(session.currentAttempt == nil)
        #expect(session.progress == progress)
    }
}
