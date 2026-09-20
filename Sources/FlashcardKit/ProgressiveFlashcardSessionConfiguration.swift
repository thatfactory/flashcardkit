import Foundation

/// Configuration used to create a deterministic progressive flashcard session.
public struct ProgressiveFlashcardSessionConfiguration: Codable, Sendable, Hashable {
    /// Number of distinct cards selected for this session.
    public let cardCount: Int

    /// Seed used for deterministic card selection and initial queue order.
    public let seed: UInt64

    /// Creates a progressive session configuration.
    ///
    /// - Parameters:
    ///   - seed: Seed used by FlashcardKit's stable deterministic random algorithm.
    ///   - cardCount: Positive number of distinct cards to select.
    public init(seed: UInt64, cardCount: Int) {
        self.cardCount = cardCount
        self.seed = seed
    }
}
