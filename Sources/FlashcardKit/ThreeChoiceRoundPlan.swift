public import Foundation

/// An immutable deterministic three-choice round with its hidden answer key.
public struct ThreeChoiceRoundPlan: Sendable {
    enum EvaluationError: Error {
        case invalidChoice(Int)
        case staleRound(expected: Int, received: Int)
    }

    /// Presentation-ready round containing exactly three distinct choices.
    public let round: ThreeChoiceRound

    private let correctChoiceID: Int

    /// Creates one deterministic round from an authoritative answer and explicit candidate pool.
    ///
    /// The candidate pool may omit the correct answer or contain it exactly once. Repeated correct answers and duplicate non-correct candidates are rejected rather than silently deduplicated.
    ///
    /// - Parameters:
    ///   - id: Host-supplied identity copied to the round without influencing ordering.
    ///   - cardID: Stable host-authored identity associated with the prompt.
    ///   - prompt: Content presented for recall.
    ///   - correctAnswer: Authoritative answer included exactly once in the visible choices.
    ///   - candidates: Ordered explicit pool from which distinct distractors are selected.
    ///   - seed: Seed controlling deterministic distractor and choice ordering.
    /// - Throws: ``ThreeChoiceRoundError`` when candidates cannot produce exactly three distinct choices.
    public init(
        id: Int,
        cardID: UUID,
        prompt: FlashcardContent,
        correctAnswer: FlashcardContent,
        candidates: [FlashcardContent],
        seed: UInt64
    ) throws {
        let distractors: [FlashcardContent]
        do {
            distractors = try Self.validatedDistractors(
                candidates,
                correctAnswer: correctAnswer
            )
        } catch let error as ThreeChoiceRoundError {
            FlashcardLogging.roundRejected(reason: error.token)
            throw error
        }

        var random = DeterministicRandom(seed: seed)
        self.init(
            id: id,
            cardID: cardID,
            prompt: prompt,
            correctAnswer: correctAnswer,
            validatedDistractors: distractors,
            random: &random
        )
        FlashcardLogging.roundCreated()
    }

    /// Evaluates a selected choice or expiry against this exact round.
    ///
    /// - Parameters:
    ///   - response: Visible choice selection or host-reported expiry.
    ///   - roundID: Identity of the round that produced the response.
    /// - Returns: The accepted response outcome and answer key.
    /// - Throws: ``ThreeChoiceRoundError/staleRound(expected:received:)`` or ``ThreeChoiceRoundError/invalidChoice(_:)`` when the response does not belong to this round.
    public func evaluate(
        _ response: ThreeChoiceResponse,
        forRoundID roundID: Int
    ) throws -> ThreeChoiceEvaluation {
        do {
            let evaluation = try evaluateWithoutLogging(response, forRoundID: roundID)
            FlashcardLogging.roundEvaluationAccepted(outcome: evaluation.outcome)
            return evaluation
        } catch EvaluationError.staleRound(let expected, let received) {
            FlashcardLogging.roundEvaluationRejected(reason: "stale-round")
            throw ThreeChoiceRoundError.staleRound(expected: expected, received: received)
        } catch EvaluationError.invalidChoice(let choiceID) {
            FlashcardLogging.roundEvaluationRejected(reason: "invalid-choice")
            throw ThreeChoiceRoundError.invalidChoice(choiceID)
        }
    }

    init(
        id: Int,
        cardID: UUID,
        prompt: FlashcardContent,
        correctAnswer: FlashcardContent,
        validatedDistractors: [FlashcardContent],
        random: inout DeterministicRandom
    ) {
        var distractors = validatedDistractors
        random.shuffle(&distractors)

        var answers = [correctAnswer] + distractors.prefix(2)
        random.shuffle(&answers)
        correctChoiceID = answers.firstIndex(of: correctAnswer)!
        round = ThreeChoiceRound(
            id: id,
            cardID: cardID,
            prompt: prompt,
            choices: answers.enumerated().map { ThreeChoice(id: $0, content: $1) }
        )
    }

    func evaluateWithoutLogging(
        _ response: ThreeChoiceResponse,
        forRoundID roundID: Int
    ) throws(EvaluationError) -> ThreeChoiceEvaluation {
        guard roundID == round.id else {
            throw EvaluationError.staleRound(expected: round.id, received: roundID)
        }

        switch response {
        case .selection(let choiceID):
            guard round.choices.contains(where: { $0.id == choiceID }) else {
                throw EvaluationError.invalidChoice(choiceID)
            }
            return ThreeChoiceEvaluation(
                roundID: round.id,
                outcome: choiceID == correctChoiceID ? .correct : .incorrect,
                selectedChoiceID: choiceID,
                correctChoiceID: correctChoiceID
            )
        case .expired:
            return ThreeChoiceEvaluation(
                roundID: round.id,
                outcome: .expired,
                selectedChoiceID: nil,
                correctChoiceID: correctChoiceID
            )
        }
    }

    // MARK: - Private

    private static func validatedDistractors(
        _ candidates: [FlashcardContent],
        correctAnswer: FlashcardContent
    ) throws -> [FlashcardContent] {
        let correctCandidateCount = candidates.count { $0 == correctAnswer }
        guard correctCandidateCount <= 1 else {
            throw ThreeChoiceRoundError.multipleCorrectAnswerCandidates(
                count: correctCandidateCount
            )
        }

        var seen = Set<FlashcardContent>()
        var distractors: [FlashcardContent] = []
        for candidate in candidates where candidate != correctAnswer {
            guard seen.insert(candidate).inserted else {
                throw ThreeChoiceRoundError.duplicateCandidateAnswer(candidate)
            }
            distractors.append(candidate)
        }

        let distinctAnswerCount = 1 + distractors.count
        guard distinctAnswerCount >= 3 else {
            throw ThreeChoiceRoundError.insufficientDistinctAnswers(
                minimum: 3,
                actual: distinctAnswerCount
            )
        }
        return distractors
    }
}

extension ThreeChoiceRoundError {
    var token: String {
        switch self {
        case .duplicateCandidateAnswer: "duplicate-candidate"
        case .insufficientDistinctAnswers: "insufficient-distinct-answers"
        case .invalidChoice: "invalid-choice"
        case .multipleCorrectAnswerCandidates: "multiple-correct-candidates"
        case .staleRound: "stale-round"
        }
    }
}
