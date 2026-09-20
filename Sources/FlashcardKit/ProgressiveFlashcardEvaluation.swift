public import Foundation

/// Progression result for one accepted host-evaluated attempt.
public struct ProgressiveFlashcardEvaluation: Codable, Sendable, Hashable {
    /// Response-mode-agnostic outcomes accepted by the progression engine.
    public enum Outcome: Codable, Sendable, Hashable {
        /// The host determined that the response was correct.
        case correct

        /// The host determined that the response window expired.
        case expired

        /// The host determined that the response was incorrect.
        case incorrect
    }

    /// Queue and stage transition produced by an accepted outcome.
    public enum Transition: Codable, Sendable, Hashable {
        /// A correct response completed the card's final stage.
        case completed

        /// The card advanced and was requeued at the supplied next stage.
        case promoted(to: FlashcardStageID)

        /// The card remained on the same stage and was requeued.
        case retained
    }

    /// Identity of the evaluated attempt.
    public let attemptID: Int

    /// Stable identity of the evaluated card.
    public let cardID: UUID

    /// Stable identity of the evaluated stage.
    public let stageID: FlashcardStageID

    /// Host-decided outcome consumed by the progression engine.
    public let outcome: Outcome

    /// Resulting card progression and queue transition.
    public let transition: Transition
}
