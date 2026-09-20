import Foundation

/// Aggregate progress for a progressive flashcard session.
public struct ProgressiveFlashcardProgress: Codable, Sendable, Hashable {
    /// Distinct selected cards that completed every stage.
    public let completedCards: Int

    /// Attempts issued so far, including the currently outstanding attempt.
    public let generatedAttempts: Int

    /// Distinct cards selected when the session was created.
    public let selectedCards: Int
}
