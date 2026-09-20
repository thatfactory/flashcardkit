import Foundation

/// Construction and evaluation failures for one reusable three-choice round.
public enum ThreeChoiceRoundError: Error, Sendable, Equatable {
    /// The explicit pool repeats one non-correct candidate answer.
    case duplicateCandidateAnswer(FlashcardContent)

    /// Correct answer plus distinct distractors cannot produce three visible choices.
    case insufficientDistinctAnswers(minimum: Int, actual: Int)

    /// The selected choice does not belong to this round.
    case invalidChoice(Int)

    /// The explicit pool contains the authoritative correct answer more than once.
    case multipleCorrectAnswerCandidates(count: Int)

    /// Evaluation targeted a round other than this plan's round.
    case staleRound(expected: Int, received: Int)
}
