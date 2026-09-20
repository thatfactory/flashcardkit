public import Foundation

/// One session-scoped opportunity to exercise a card's current stage.
public struct ProgressiveFlashcardAttempt: Identifiable, Codable, Sendable, Hashable {
    /// Monotonic zero-based identity scoped to the containing session.
    public let id: Int

    /// Stable host-authored card identity.
    public let cardID: UUID

    /// Zero-based position of the stage in the card's ordered stages.
    public let stageIndex: Int

    /// Exact stage currently being exercised.
    public let stage: FlashcardStage
}
