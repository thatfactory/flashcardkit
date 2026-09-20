import Foundation
import Testing

@testable import FlashcardKit

@Suite("Three-choice round plans")
struct ThreeChoiceRoundPlanTests {
    @Test("A separate correct answer and two distractors produce one valid round")
    func separateCorrectAnswer() throws {
        let correct = try content("B")
        let plan = try makePlan(
            correctAnswer: correct,
            candidates: [content("A"), content("C")]
        )

        #expect(plan.round.choices.count == 3)
        #expect(Set(plan.round.choices.map(\.content)).count == 3)
        #expect(plan.round.choices.count { $0.content == correct } == 1)
    }

    @Test("A closed candidate pool may contain the correct answer once")
    func closedCandidatePool() throws {
        let correct = try content("B")
        let plan = try makePlan(
            correctAnswer: correct,
            candidates: [content("A"), correct, content("C")]
        )

        #expect(Set(plan.round.choices.map(\.content)) == Set(try [content("A"), correct, content("C")]))
        #expect(plan.round.choices.count { $0.content == correct } == 1)
    }

    @Test("Candidate selection and ordering are deterministic")
    func deterministicConstruction() throws {
        let candidates = try [content("A"), content("C"), content("D"), content("E")]
        let first = try makePlan(correctAnswer: content("B"), candidates: candidates, seed: 42)
        let second = try makePlan(correctAnswer: content("B"), candidates: candidates, seed: 42)

        #expect(first.round == second.round)
        #expect(first.round.choices.count == 3)
    }

    @Test("Round identity does not influence deterministic choice ordering")
    func identityIsOrthogonalToSeed() throws {
        let candidates = try [content("A"), content("C"), content("D")]
        let first = try makePlan(
            id: 7,
            correctAnswer: content("B"),
            candidates: candidates,
            seed: 3
        )
        let second = try makePlan(
            id: 99,
            correctAnswer: content("B"),
            candidates: candidates,
            seed: 3
        )

        #expect(first.round.id == 7)
        #expect(second.round.id == 99)
        #expect(first.round.choices == second.round.choices)
    }

    @Test("Repeated correct-answer candidates are rejected")
    func multipleCorrectCandidates() throws {
        let correct = try content("B")

        #expect(throws: ThreeChoiceRoundError.multipleCorrectAnswerCandidates(count: 2)) {
            try makePlan(
                correctAnswer: correct,
                candidates: [correct, content("A"), correct, content("C")]
            )
        }
    }

    @Test("Repeated non-correct candidates are rejected")
    func duplicateCandidate() throws {
        let duplicate = try content("A")

        #expect(throws: ThreeChoiceRoundError.duplicateCandidateAnswer(duplicate)) {
            try makePlan(
                correctAnswer: content("B"),
                candidates: [duplicate, content("C"), duplicate]
            )
        }
    }

    @Test("Insufficient candidate pools are rejected with their visible-answer count")
    func insufficientCandidates() throws {
        let correct = try content("B")

        #expect(throws: ThreeChoiceRoundError.insufficientDistinctAnswers(minimum: 3, actual: 2)) {
            try makePlan(correctAnswer: correct, candidates: [content("A")])
        }
        #expect(throws: ThreeChoiceRoundError.insufficientDistinctAnswers(minimum: 3, actual: 2)) {
            try makePlan(correctAnswer: correct, candidates: [content("A"), correct])
        }
    }

    @Test("Valid selections and expiry produce answer-key evaluations")
    func evaluation() throws {
        let correct = try content("B")
        let plan = try makePlan(
            correctAnswer: correct,
            candidates: [content("A"), content("C")]
        )
        let correctChoice = try #require(plan.round.choices.first { $0.content == correct })
        let incorrectChoice = try #require(plan.round.choices.first { $0.content != correct })

        let correctEvaluation = try plan.evaluate(
            .selection(choiceID: correctChoice.id),
            forRoundID: plan.round.id
        )
        let incorrectEvaluation = try plan.evaluate(
            .selection(choiceID: incorrectChoice.id),
            forRoundID: plan.round.id
        )
        let expiredEvaluation = try plan.evaluate(.expired, forRoundID: plan.round.id)

        #expect(correctEvaluation.outcome == .correct)
        #expect(correctEvaluation.correctChoiceID == correctChoice.id)
        #expect(incorrectEvaluation.outcome == .incorrect)
        #expect(incorrectEvaluation.correctChoiceID == correctChoice.id)
        #expect(expiredEvaluation.outcome == .expired)
        #expect(expiredEvaluation.selectedChoiceID == nil)
        #expect(expiredEvaluation.correctChoiceID == correctChoice.id)
    }

    @Test("Evaluation rejects stale rounds before unknown choices")
    func evaluationValidation() throws {
        let plan = try makePlan(
            correctAnswer: content("B"),
            candidates: [content("A"), content("C")]
        )

        #expect(throws: ThreeChoiceRoundError.staleRound(expected: 7, received: 99)) {
            try plan.evaluate(.selection(choiceID: 99), forRoundID: 99)
        }
        #expect(throws: ThreeChoiceRoundError.invalidChoice(99)) {
            try plan.evaluate(.selection(choiceID: 99), forRoundID: plan.round.id)
        }
    }

    @Test("The plan is Sendable and emitted values retain their value contracts")
    func valueContracts() throws {
        let plan = try makePlan(
            correctAnswer: content("B"),
            candidates: [content("A"), content("C")]
        )
        let evaluation = try plan.evaluate(.expired, forRoundID: plan.round.id)

        requireSendable(plan)
        requireValueContract(plan.round)
        requireValueContract(evaluation)
    }

    // MARK: - Private

    private func content(_ value: String) throws -> FlashcardContent {
        try FlashcardContent(text: value)
    }

    private func makePlan(
        id: Int = 7,
        correctAnswer: FlashcardContent,
        candidates: [FlashcardContent],
        seed: UInt64 = 1
    ) throws -> ThreeChoiceRoundPlan {
        try ThreeChoiceRoundPlan(
            id: id,
            cardID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            prompt: content("prompt"),
            correctAnswer: correctAnswer,
            candidates: candidates,
            seed: seed
        )
    }

    private func requireSendable<Value: Sendable>(_ value: Value) {
        _ = value
    }

    private func requireValueContract<Value: Codable & Sendable & Hashable>(_ value: Value) {
        _ = value
    }
}
