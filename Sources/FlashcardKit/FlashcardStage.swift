import Foundation

/// One host-authored step in a flashcard's ordered recall sequence.
public struct FlashcardStage: Identifiable, Codable, Sendable, Hashable {
    /// Stable stage identity supplied by the host.
    public let id: FlashcardStageID

    /// Content presented for this recall stage.
    public let prompt: FlashcardContent

    /// Content revealed or evaluated as this stage's answer.
    public let answer: FlashcardContent

    /// Creates an ordered recall stage from validated prompt and answer content.
    ///
    /// - Parameters:
    ///   - id: Stable host-authored identity unique within its card.
    ///   - prompt: Content presented for recall.
    ///   - answer: Content revealed or evaluated as the answer.
    public init(
        id: FlashcardStageID,
        prompt: FlashcardContent,
        answer: FlashcardContent
    ) {
        self.id = id
        self.prompt = prompt
        self.answer = answer
    }
}
