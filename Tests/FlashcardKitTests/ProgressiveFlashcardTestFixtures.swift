import Foundation

@testable import FlashcardKit

/// Provides deterministic staged cards for progressive-session tests.
enum ProgressiveFlashcardTestFixtures {
    static var cards: [Flashcard] {
        get throws {
            try (1...4).map { try card($0) }
        }
    }

    static func card(
        _ value: Int,
        stageCount: Int = 2
    ) throws -> Flashcard {
        try Flashcard(
            id: cardID(value),
            stages: (0..<stageCount).map { stageIndex in
                FlashcardStage(
                    id: FlashcardStageID(rawValue: "stage-\(stageIndex)"),
                    prompt: try FlashcardContent(text: "prompt-\(value)-\(stageIndex)"),
                    answer: try FlashcardContent(text: "answer-\(value)-\(stageIndex)")
                )
            }
        )
    }

    static func cardID(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}
