public import Foundation

/// Validation and submission failures from a progressive flashcard session.
public enum ProgressiveFlashcardSessionError: Error, Sendable, Equatable {
    /// The requested card count exceeded the supplied cards.
    case cardCountExceedsAvailableCards(requested: Int, available: Int)

    /// More than one source card used the same stable identity.
    case duplicateCardID(UUID)

    /// The submitted attempt identity was negative or had not been issued.
    case invalidAttempt(Int)

    /// The requested card count was not positive.
    case invalidCardCount(Int)

    /// An outcome was submitted after every selected card completed.
    case sessionComplete

    /// An outcome targeted an earlier attempt instead of the current attempt.
    case staleAttempt(expected: Int, received: Int)
}
