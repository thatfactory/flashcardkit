import Foundation

/// Validation failures produced while creating a flashcard.
public enum FlashcardError: Error, Sendable, Equatable {
    /// More than one stage used the same host-authored identity.
    case duplicateStageID(FlashcardStageID)

    /// No recall stage was supplied.
    case missingStages
}
