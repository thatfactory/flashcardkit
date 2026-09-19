public import Foundation

/// Controls how prompt cards are ordered when a session plan is created.
public enum ThreeChoiceRoundOrdering: Codable, Sendable, Hashable {
    /// Preserve the order supplied by the host.
    case source

    /// Canonicalize cards by identity, then shuffle them using the configured seed.
    case shuffled
}

/// Configuration used to create a deterministic three-choice session.
public struct ThreeChoiceSessionConfiguration: Codable, Sendable, Hashable {
    /// Seed used for prompt, distractor, and choice ordering.
    public let seed: UInt64

    /// Number of rounds to play, or `nil` to use every card once.
    public let roundCount: Int?

    /// Prompt ordering policy.
    public let ordering: ThreeChoiceRoundOrdering

    /// Creates a session configuration.
    ///
    /// - Parameters:
    ///   - seed: Seed used by FlashcardKit's stable deterministic random algorithm.
    ///   - roundCount: Positive round count, or `nil` to use every card once.
    ///   - ordering: Prompt ordering policy.
    public init(
        seed: UInt64,
        roundCount: Int? = nil,
        ordering: ThreeChoiceRoundOrdering = .shuffled
    ) {
        self.seed = seed
        self.roundCount = roundCount
        self.ordering = ordering
    }
}

/// One visible answer choice in a three-choice round.
public struct ThreeChoice: Identifiable, Codable, Sendable, Hashable {
    /// Deterministic identifier scoped to the containing round.
    public let id: Int

    /// Content presented as the possible answer.
    public let content: FlashcardContent
}

/// A presentation-ready prompt and its three possible answers.
public struct ThreeChoiceRound: Identifiable, Codable, Sendable, Hashable {
    /// Deterministic zero-based position in the session.
    public let id: Int

    /// Stable identity of the card being recalled.
    public let cardID: UUID

    /// Content presented for recall.
    public let prompt: FlashcardContent

    /// Three distinct possible answers in deterministic order.
    public let choices: [ThreeChoice]
}

/// A host-submitted response to the currently visible round.
public enum ThreeChoiceResponse: Sendable, Hashable {
    /// The player selected a visible choice.
    case selection(choiceID: Int)

    /// The host-owned answer window expired.
    case expired
}

/// The deterministic outcome of one accepted response.
public struct ThreeChoiceEvaluation: Codable, Sendable, Hashable {
    /// Possible outcomes for an accepted response.
    public enum Outcome: Codable, Sendable, Hashable {
        /// The selected choice matched the answer.
        case correct

        /// The selected choice did not match the answer.
        case incorrect

        /// The host reported that its answer window expired.
        case expired
    }

    /// Identity of the evaluated round.
    public let roundID: Int

    /// Result of the submitted response.
    public let outcome: Outcome

    /// Selected choice identity, or `nil` for expiry.
    public let selectedChoiceID: Int?

    /// Choice identity containing the correct answer.
    public let correctChoiceID: Int
}

/// Finite session progress after zero or more accepted responses.
public struct ThreeChoiceProgress: Codable, Sendable, Hashable {
    /// Number of rounds already evaluated.
    public let completedRounds: Int

    /// Total number of planned rounds.
    public let totalRounds: Int
}

/// Validation and submission failures from a three-choice session.
public enum ThreeChoiceSessionError: Error, Sendable, Equatable {
    /// More than one card used the same stable identity.
    case duplicateCardID(UUID)

    /// Fewer than three cards were supplied.
    case insufficientCards(minimum: Int, actual: Int)

    /// The supplied cards contain fewer than three distinct visible answers.
    case insufficientDistinctAnswers(minimum: Int, actual: Int)

    /// The requested round count was not positive.
    case invalidRoundCount(Int)

    /// The requested round count exceeded the supplied card count.
    case roundCountExceedsAvailableCards(requested: Int, available: Int)

    /// A response was submitted after the final round.
    case sessionComplete

    /// A response targeted a round other than the current round.
    case staleRound(expected: Int, received: Int)

    /// The selected choice does not belong to the current round.
    case invalidChoice(Int)
}
