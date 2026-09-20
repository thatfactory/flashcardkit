import Foundation
import Testing

@testable import FlashcardKit

@Suite("Progressive flashcard sessions")
struct ProgressiveFlashcardSessionTests {
    @Test("Seeded selection is distinct and independent of input order")
    func deterministicSelection() throws {
        let cards = try ProgressiveFlashcardTestFixtures.cards
        let configuration = ProgressiveFlashcardSessionConfiguration(seed: 42, cardCount: 3)
        var original = try ProgressiveFlashcardSession(cards: cards, configuration: configuration)
        var reversed = try ProgressiveFlashcardSession(
            cards: cards.reversed(),
            configuration: configuration
        )

        var originalOrder: [UUID] = []
        var reversedOrder: [UUID] = []
        #expect(
            original.progress
                == ProgressiveFlashcardProgress(
                    completedCards: 0,
                    generatedAttempts: 1,
                    selectedCards: configuration.cardCount
                )
        )
        for _ in 0..<configuration.cardCount {
            let originalAttempt = try #require(original.currentAttempt)
            let reversedAttempt = try #require(reversed.currentAttempt)
            originalOrder.append(originalAttempt.cardID)
            reversedOrder.append(reversedAttempt.cardID)
            _ = try original.submit(.expired, forAttemptID: originalAttempt.id)
            _ = try reversed.submit(.expired, forAttemptID: reversedAttempt.id)
        }

        #expect(Set(originalOrder).count == configuration.cardCount)
        #expect(originalOrder == reversedOrder)
    }

    @Test("Identical outcome scripts reproduce attempts and evaluations")
    func deterministicReplay() throws {
        let configuration = ProgressiveFlashcardSessionConfiguration(seed: 7, cardCount: 3)
        var first = try ProgressiveFlashcardSession(
            cards: ProgressiveFlashcardTestFixtures.cards,
            configuration: configuration
        )
        var second = try ProgressiveFlashcardSession(
            cards: ProgressiveFlashcardTestFixtures.cards.reversed(),
            configuration: configuration
        )
        let outcomes: [ProgressiveFlashcardEvaluation.Outcome] = [
            .incorrect,
            .correct,
            .expired,
            .correct,
            .correct,
            .correct,
            .correct,
            .correct,
        ]

        for outcome in outcomes {
            let firstAttempt = try #require(first.currentAttempt)
            let secondAttempt = try #require(second.currentAttempt)
            #expect(firstAttempt == secondAttempt)

            let firstEvaluation = try first.submit(outcome, forAttemptID: firstAttempt.id)
            let secondEvaluation = try second.submit(outcome, forAttemptID: secondAttempt.id)

            #expect(firstEvaluation == secondEvaluation)
            #expect(first.currentAttempt == second.currentAttempt)
            #expect(first.progress == second.progress)
        }

        #expect(first.isComplete)
        #expect(second.isComplete)
        #expect(first.currentAttempt == nil)
        #expect(second.currentAttempt == nil)
    }

    @Test("Correct answers promote in stage order and requeue at the tail")
    func promotionAndTailRequeue() throws {
        var session = try ProgressiveFlashcardSession(
            cards: [
                ProgressiveFlashcardTestFixtures.card(1),
                ProgressiveFlashcardTestFixtures.card(2),
            ],
            configuration: ProgressiveFlashcardSessionConfiguration(seed: 1, cardCount: 2)
        )
        let first = try #require(session.currentAttempt)

        let evaluation = try session.submit(.correct, forAttemptID: first.id)
        let second = try #require(session.currentAttempt)

        #expect(evaluation.stageID == first.stage.id)
        #expect(evaluation.transition == .promoted(to: FlashcardStageID(rawValue: "stage-1")))
        #expect(second.cardID != first.cardID)
        #expect(second.stageIndex == 0)

        _ = try session.submit(.expired, forAttemptID: second.id)
        let promoted = try #require(session.currentAttempt)
        #expect(promoted.cardID == first.cardID)
        #expect(promoted.stageIndex == 1)
        #expect(promoted.id == 2)
    }

    @Test("Incorrect and expired outcomes retain the stage and use new attempt IDs")
    func retainedStages() throws {
        var session = try ProgressiveFlashcardSession(
            cards: [ProgressiveFlashcardTestFixtures.card(1)],
            configuration: ProgressiveFlashcardSessionConfiguration(seed: 1, cardCount: 1)
        )
        let first = try #require(session.currentAttempt)

        let incorrect = try session.submit(.incorrect, forAttemptID: first.id)
        let second = try #require(session.currentAttempt)
        let expired = try session.submit(.expired, forAttemptID: second.id)
        let third = try #require(session.currentAttempt)

        #expect(incorrect.transition == .retained)
        #expect(expired.transition == .retained)
        #expect(second.cardID == first.cardID)
        #expect(second.stageIndex == first.stageIndex)
        #expect(second.id == 1)
        #expect(third.stageIndex == first.stageIndex)
        #expect(third.id == 2)
        #expect(
            session.progress
                == ProgressiveFlashcardProgress(
                    completedCards: 0,
                    generatedAttempts: 3,
                    selectedCards: 1
                )
        )
    }

    @Test("A single multi-stage card advances immediately when no alternative exists")
    func singleCardPromotion() throws {
        var session = try ProgressiveFlashcardSession(
            cards: [ProgressiveFlashcardTestFixtures.card(1)],
            configuration: ProgressiveFlashcardSessionConfiguration(seed: 1, cardCount: 1)
        )
        let first = try #require(session.currentAttempt)

        _ = try session.submit(.correct, forAttemptID: first.id)
        let second = try #require(session.currentAttempt)

        #expect(second.cardID == first.cardID)
        #expect(second.stageIndex == 1)
        #expect(second.id == 1)
        #expect(!session.isComplete)
    }

    @Test("Completion requires every selected card's final stage")
    func completion() throws {
        var session = try ProgressiveFlashcardSession(
            cards: [ProgressiveFlashcardTestFixtures.card(1)],
            configuration: ProgressiveFlashcardSessionConfiguration(seed: 1, cardCount: 1)
        )
        let first = try #require(session.currentAttempt)
        _ = try session.submit(.correct, forAttemptID: first.id)
        let final = try #require(session.currentAttempt)

        let evaluation = try session.submit(.correct, forAttemptID: final.id)

        #expect(evaluation.transition == .completed)
        #expect(session.isComplete)
        #expect(session.currentAttempt == nil)
        #expect(
            session.progress
                == ProgressiveFlashcardProgress(
                    completedCards: 1,
                    generatedAttempts: 2,
                    selectedCards: 1
                )
        )
    }

    @Test("The sole unfinished card can repeat after other cards complete")
    func soleRemainingCardRepeats() throws {
        var session = try ProgressiveFlashcardSession(
            cards: [
                ProgressiveFlashcardTestFixtures.card(1, stageCount: 1),
                ProgressiveFlashcardTestFixtures.card(2, stageCount: 1),
            ],
            configuration: ProgressiveFlashcardSessionConfiguration(seed: 2, cardCount: 2)
        )
        let first = try #require(session.currentAttempt)
        _ = try session.submit(.correct, forAttemptID: first.id)
        let remaining = try #require(session.currentAttempt)

        _ = try session.submit(.incorrect, forAttemptID: remaining.id)
        let retry = try #require(session.currentAttempt)

        #expect(retry.cardID == remaining.cardID)
        #expect(retry.stageIndex == remaining.stageIndex)
        #expect(session.progress.completedCards == 1)
        #expect(!session.isComplete)
    }

    @Test("Public progressive values satisfy persistence and concurrency contracts")
    func valueContracts() throws {
        let configuration = ProgressiveFlashcardSessionConfiguration(seed: 1, cardCount: 1)
        var session = try ProgressiveFlashcardSession(
            cards: [ProgressiveFlashcardTestFixtures.card(1)],
            configuration: configuration
        )
        let attempt = try #require(session.currentAttempt)
        let evaluation = try session.submit(.expired, forAttemptID: attempt.id)

        requireSendable(session)
        try expectRoundTrip(configuration)
        try expectRoundTrip(attempt)
        try expectRoundTrip(evaluation)
        try expectRoundTrip(session.progress)
    }

    // MARK: - Private

    private func requireSendable<Value: Sendable>(_ value: Value) {
        _ = value
    }

    private func expectRoundTrip<Value: Codable & Equatable>(_ value: Value) throws {
        let data = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Value.self, from: data) == value)
    }
}
