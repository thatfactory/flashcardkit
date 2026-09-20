import Foundation

/// A deterministic session that advances cards through ordered recall stages.
public struct ProgressiveFlashcardSession: Sendable {
    private struct PendingCard: Sendable {
        let card: Flashcard
        var stageIndex: Int
    }

    private var completedCardCount = 0
    private var currentAttemptID: Int?
    private var nextAttemptID: Int
    private var queue: [PendingCard]
    private let selectedCardCount: Int

    /// The attempt awaiting a host-decided outcome, or `nil` after completion.
    public var currentAttempt: ProgressiveFlashcardAttempt? {
        guard let currentAttemptID, let pending = queue.first else {
            return nil
        }
        return ProgressiveFlashcardAttempt(
            id: currentAttemptID,
            cardID: pending.card.id,
            stageIndex: pending.stageIndex,
            stage: pending.card.stages[pending.stageIndex]
        )
    }

    /// Current card completion and generated-attempt counts.
    public var progress: ProgressiveFlashcardProgress {
        ProgressiveFlashcardProgress(
            completedCards: completedCardCount,
            generatedAttempts: nextAttemptID,
            selectedCards: selectedCardCount
        )
    }

    /// Whether every selected card completed its final stage.
    public var isComplete: Bool {
        completedCardCount == selectedCardCount
    }

    /// Creates a deterministic progressive session from host-owned cards.
    ///
    /// - Parameters:
    ///   - cards: Cards eligible for deterministic selection.
    ///   - configuration: Seed and distinct-card selection count.
    /// - Throws: ``ProgressiveFlashcardSessionError`` when the source cards or configuration are invalid.
    public init(
        cards: [Flashcard],
        configuration: ProgressiveFlashcardSessionConfiguration
    ) throws {
        guard configuration.cardCount > 0 else {
            FlashcardLogging.progressiveSessionRejected(reason: "invalid-card-count")
            throw ProgressiveFlashcardSessionError.invalidCardCount(configuration.cardCount)
        }

        var cardIDs = Set<UUID>()
        for card in cards where !cardIDs.insert(card.id).inserted {
            FlashcardLogging.progressiveSessionRejected(reason: "duplicate-card-id")
            throw ProgressiveFlashcardSessionError.duplicateCardID(card.id)
        }

        guard configuration.cardCount <= cards.count else {
            FlashcardLogging.progressiveSessionRejected(reason: "card-count-exceeds-cards")
            throw ProgressiveFlashcardSessionError.cardCountExceedsAvailableCards(
                requested: configuration.cardCount,
                available: cards.count
            )
        }

        var orderedCards = cards.sorted { $0.id.uuidString < $1.id.uuidString }
        var random = DeterministicRandom(seed: configuration.seed)
        random.shuffle(&orderedCards)
        let selectedCards = orderedCards.prefix(configuration.cardCount)

        queue = selectedCards.map { PendingCard(card: $0, stageIndex: 0) }
        currentAttemptID = 0
        nextAttemptID = 1
        selectedCardCount = configuration.cardCount
        FlashcardLogging.progressiveSessionCreated(cards: selectedCardCount)
    }

    /// Applies one host-decided outcome to the exact current attempt.
    ///
    /// - Parameters:
    ///   - outcome: Correct, incorrect, or expired result decided by the host's evaluation mechanism.
    ///   - attemptID: Identity of the attempt that produced the outcome.
    /// - Returns: The accepted outcome and resulting stage transition.
    /// - Throws: ``ProgressiveFlashcardSessionError`` when the session is complete or the attempt identity is invalid or stale. Rejected submissions do not mutate the session.
    public mutating func submit(
        _ outcome: ProgressiveFlashcardEvaluation.Outcome,
        forAttemptID attemptID: Int
    ) throws -> ProgressiveFlashcardEvaluation {
        guard let currentAttemptID else {
            FlashcardLogging.progressiveAttemptRejected(reason: "session-complete")
            throw ProgressiveFlashcardSessionError.sessionComplete
        }
        guard attemptID >= 0, attemptID < nextAttemptID else {
            FlashcardLogging.progressiveAttemptRejected(reason: "invalid-attempt")
            throw ProgressiveFlashcardSessionError.invalidAttempt(attemptID)
        }
        guard attemptID == currentAttemptID else {
            FlashcardLogging.progressiveAttemptRejected(reason: "stale-attempt")
            throw ProgressiveFlashcardSessionError.staleAttempt(
                expected: currentAttemptID,
                received: attemptID
            )
        }

        var pending = queue.removeFirst()
        let evaluatedStage = pending.card.stages[pending.stageIndex]
        let transition: ProgressiveFlashcardEvaluation.Transition
        switch outcome {
        case .correct where pending.card.stages.indices.contains(pending.stageIndex + 1):
            pending.stageIndex += 1
            queue.append(pending)
            transition = .promoted(to: pending.card.stages[pending.stageIndex].id)
        case .correct:
            completedCardCount += 1
            transition = .completed
        case .expired, .incorrect:
            queue.append(pending)
            transition = .retained
        }

        issueNextAttempt()
        let evaluation = ProgressiveFlashcardEvaluation(
            attemptID: attemptID,
            cardID: pending.card.id,
            stageID: evaluatedStage.id,
            outcome: outcome,
            transition: transition
        )
        FlashcardLogging.progressiveAttemptAccepted(
            outcome: outcome,
            transition: transition,
            completedCards: completedCardCount,
            selectedCards: selectedCardCount,
            generatedAttempts: nextAttemptID
        )
        if isComplete {
            FlashcardLogging.progressiveSessionCompleted(
                cards: selectedCardCount,
                attempts: nextAttemptID
            )
        }
        return evaluation
    }

    // MARK: - Private

    private mutating func issueNextAttempt() {
        guard !queue.isEmpty else {
            currentAttemptID = nil
            return
        }
        currentAttemptID = nextAttemptID
        nextAttemptID += 1
    }
}
