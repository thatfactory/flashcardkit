import Foundation

/// A deterministic finite recall session with exactly three answers per round.
public struct ThreeChoiceSession: Sendable {
    private let plan: [ThreeChoiceRoundPlan]
    private var currentIndex = 0

    /// The round awaiting a response, or `nil` after completion.
    public var currentRound: ThreeChoiceRound? {
        guard plan.indices.contains(currentIndex) else { return nil }
        return plan[currentIndex].round
    }

    /// Current completion counts for the finite session.
    public var progress: ThreeChoiceProgress {
        ThreeChoiceProgress(completedRounds: currentIndex, totalRounds: plan.count)
    }

    /// Whether every planned round has received an accepted response.
    public var isComplete: Bool {
        currentIndex == plan.count
    }

    /// Creates a complete deterministic round plan from host-owned cards.
    ///
    /// - Parameters:
    ///   - cards: Cards eligible for the session.
    ///   - configuration: Seed, round count, and prompt ordering policy.
    /// - Throws: ``ThreeChoiceSessionError`` when cards or configuration cannot produce every requested round.
    public init(cards: [Flashcard], configuration: ThreeChoiceSessionConfiguration) throws {
        guard cards.count >= 3 else {
            FlashcardLogging.sessionRejected(reason: "insufficient-cards")
            throw ThreeChoiceSessionError.insufficientCards(minimum: 3, actual: cards.count)
        }

        var cardIDs = Set<UUID>()
        for card in cards where !cardIDs.insert(card.id).inserted {
            FlashcardLogging.sessionRejected(reason: "duplicate-card-id")
            throw ThreeChoiceSessionError.duplicateCardID(card.id)
        }

        let distinctAnswerCount = Set(cards.map(\.answer)).count
        guard distinctAnswerCount >= 3 else {
            FlashcardLogging.sessionRejected(reason: "insufficient-distinct-answers")
            throw ThreeChoiceSessionError.insufficientDistinctAnswers(
                minimum: 3,
                actual: distinctAnswerCount
            )
        }

        let roundCount = try Self.roundCount(for: cards.count, requested: configuration.roundCount)
        var random = DeterministicRandom(seed: configuration.seed)
        let orderedCards = Self.orderedCards(cards, ordering: configuration.ordering, random: &random)
        plan = Self.makePlan(
            promptCards: Array(orderedCards.prefix(roundCount)),
            allCards: orderedCards,
            random: &random
        )
        FlashcardLogging.sessionCreated(rounds: plan.count)
    }

    /// Evaluates a response for the exact current round and advances after success.
    ///
    /// - Parameters:
    ///   - response: A selected choice or host-reported expiry.
    ///   - roundID: Identity of the round to which the response belongs.
    /// - Returns: The accepted response outcome and answer key.
    /// - Throws: ``ThreeChoiceSessionError`` when the session is complete, the round is stale, or a choice is unknown. Rejected responses do not advance progress.
    public mutating func submit(
        _ response: ThreeChoiceResponse,
        forRoundID roundID: Int
    ) throws -> ThreeChoiceEvaluation {
        guard let plannedRound = plan[safe: currentIndex] else {
            FlashcardLogging.responseRejected(reason: "session-complete")
            throw ThreeChoiceSessionError.sessionComplete
        }
        let evaluation: ThreeChoiceEvaluation
        do {
            evaluation = try plannedRound.evaluateWithoutLogging(
                response,
                forRoundID: roundID
            )
        } catch ThreeChoiceRoundPlan.EvaluationError.staleRound(let expected, let received) {
            FlashcardLogging.responseRejected(reason: "stale-round")
            throw ThreeChoiceSessionError.staleRound(expected: expected, received: received)
        } catch ThreeChoiceRoundPlan.EvaluationError.invalidChoice(let choiceID) {
            FlashcardLogging.responseRejected(reason: "invalid-choice")
            throw ThreeChoiceSessionError.invalidChoice(choiceID)
        }

        currentIndex += 1
        FlashcardLogging.responseAccepted(
            outcome: evaluation.outcome,
            completed: currentIndex,
            total: plan.count
        )
        return evaluation
    }

    private static func roundCount(for available: Int, requested: Int?) throws -> Int {
        guard let requested else { return available }
        guard requested > 0 else {
            FlashcardLogging.sessionRejected(reason: "invalid-round-count")
            throw ThreeChoiceSessionError.invalidRoundCount(requested)
        }
        guard requested <= available else {
            FlashcardLogging.sessionRejected(reason: "round-count-exceeds-cards")
            throw ThreeChoiceSessionError.roundCountExceedsAvailableCards(
                requested: requested,
                available: available
            )
        }
        return requested
    }

    private static func orderedCards(
        _ cards: [Flashcard],
        ordering: ThreeChoiceRoundOrdering,
        random: inout DeterministicRandom
    ) -> [Flashcard] {
        guard ordering == .shuffled else { return cards }
        var ordered = cards.sorted { $0.id.uuidString < $1.id.uuidString }
        random.shuffle(&ordered)
        return ordered
    }

    private static func makePlan(
        promptCards: [Flashcard],
        allCards: [Flashcard],
        random: inout DeterministicRandom
    ) -> [ThreeChoiceRoundPlan] {
        promptCards.enumerated().map { roundID, card in
            var seenAnswers = Set([card.answer])
            let distractors = allCards.compactMap { candidate -> FlashcardContent? in
                guard seenAnswers.insert(candidate.answer).inserted else { return nil }
                return candidate.answer
            }
            return ThreeChoiceRoundPlan(
                id: roundID,
                cardID: card.id,
                prompt: card.prompt,
                correctAnswer: card.answer,
                validatedDistractors: distractors,
                random: &random
            )
        }
    }
}

extension Collection {
    fileprivate subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
