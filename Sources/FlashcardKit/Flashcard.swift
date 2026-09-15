import Foundation

/// Host-authored prompt-and-answer content used by recall activities.
public struct Flashcard: Identifiable, Codable, Sendable, Hashable {
    /// The stable identity supplied by the host.
    public let id: UUID

    /// Content presented for recall.
    public let prompt: FlashcardContent

    /// Content revealed or evaluated as the answer.
    public let answer: FlashcardContent

    /// Creates a flashcard from validated prompt and answer content.
    ///
    /// - Parameters:
    ///   - id: Stable host-owned identity.
    ///   - prompt: Content presented for recall.
    ///   - answer: Content revealed or evaluated as the answer.
    public init(id: UUID, prompt: FlashcardContent, answer: FlashcardContent) {
        self.id = id
        self.prompt = prompt
        self.answer = answer
    }
}
