import Testing

@testable import FlashcardKit

@Suite("Flashcard logging")
struct FlashcardLoggingTests {
    @Test("Messages use the package identity and expose no card content")
    func packageIdentity() {
        #expect(FlashcardLogging.subsystem == "com.thatfactory.flashcardkit")
        #expect(FlashcardLogging.formatted("session created | rounds=3") == "🃏 session created | rounds=3")
    }

    @Test(
        "Evaluation outcomes have stable privacy-safe tokens",
        arguments: [
            OutcomeToken(outcome: .correct, token: "correct"),
            OutcomeToken(outcome: .incorrect, token: "incorrect"),
            OutcomeToken(outcome: .expired, token: "expired"),
        ]
    )
    func outcomeTokens(example: OutcomeToken) {
        #expect(example.outcome.token == example.token)
    }

    @Test(
        "Progressive outcomes have stable privacy-safe tokens",
        arguments: [
            ProgressiveOutcomeToken(outcome: .correct, token: "correct"),
            ProgressiveOutcomeToken(outcome: .expired, token: "expired"),
            ProgressiveOutcomeToken(outcome: .incorrect, token: "incorrect"),
        ]
    )
    func progressiveOutcomeTokens(example: ProgressiveOutcomeToken) {
        #expect(example.outcome.token == example.token)
    }

    @Test(
        "Progressive transitions have stable privacy-safe tokens",
        arguments: [
            ProgressiveTransitionToken(transition: .completed, token: "completed"),
            ProgressiveTransitionToken(
                transition: .promoted(to: FlashcardStageID(rawValue: "private-stage")),
                token: "promoted"
            ),
            ProgressiveTransitionToken(transition: .retained, token: "retained"),
        ]
    )
    func progressiveTransitionTokens(example: ProgressiveTransitionToken) {
        #expect(example.transition.token == example.token)
    }

    @Test("Progressive messages expose only aggregate state")
    func progressiveMessagePrivacy() {
        let accepted = FlashcardLogging.progressiveAttemptAcceptedMessage(
            outcome: .correct,
            transition: .promoted(to: FlashcardStageID(rawValue: "private-stage")),
            completedCards: 1,
            selectedCards: 3,
            generatedAttempts: 4
        )
        let messages = [
            accepted,
            FlashcardLogging.progressiveAttemptRejectedMessage(reason: "stale-attempt"),
            FlashcardLogging.progressiveSessionCompletedMessage(cards: 3, attempts: 7),
            FlashcardLogging.progressiveSessionCreatedMessage(cards: 3),
            FlashcardLogging.progressiveSessionRejectedMessage(reason: "invalid-card-count"),
        ]

        #expect(
            FlashcardLogging.formatted(accepted)
                == "🃏 progressive attempt accepted | outcome=correct, transition=promoted, completed=1, selected=3, attempts=4"
        )
        #expect(messages[1] == "progressive attempt rejected | reason=stale-attempt")
        #expect(messages[2] == "progressive session completed | cards=3, attempts=7")
        #expect(messages[3] == "progressive session created | cards=3")
        #expect(messages[4] == "progressive session rejected | reason=invalid-card-count")
        for forbiddenValue in [
            "private-stage",
            "00000000-0000-0000-0000-000000000001",
            "prompt",
            "answer",
            "asset-reference",
        ] {
            #expect(messages.allSatisfy { !$0.contains(forbiddenValue) })
        }
    }

    @Test("Round-plan messages expose only stable result classes")
    func roundPlanMessagePrivacy() {
        let messages = [
            FlashcardLogging.roundCreatedMessage(),
            FlashcardLogging.roundRejectedMessage(reason: "duplicate-candidate"),
            FlashcardLogging.roundEvaluationAcceptedMessage(outcome: .correct),
            FlashcardLogging.roundEvaluationAcceptedMessage(outcome: .incorrect),
            FlashcardLogging.roundEvaluationAcceptedMessage(outcome: .expired),
            FlashcardLogging.roundEvaluationRejectedMessage(reason: "stale-round"),
        ]

        #expect(messages[0] == "round created | choices=3")
        #expect(messages[1] == "round rejected | reason=duplicate-candidate")
        #expect(messages[2] == "round evaluated | outcome=correct")
        #expect(messages[3] == "round evaluated | outcome=incorrect")
        #expect(messages[4] == "round evaluated | outcome=expired")
        #expect(messages[5] == "round evaluation rejected | reason=stale-round")
        for forbiddenValue in [
            "prompt",
            "answer",
            "asset-reference",
            "00000000-0000-0000-0000-000000000001",
            "round-id=7",
            "choice-id=2",
            "seed=42",
        ] {
            #expect(messages.allSatisfy { !$0.contains(forbiddenValue) })
        }
    }
}

extension FlashcardLoggingTests {
    struct OutcomeToken: Sendable, CustomTestStringConvertible {
        let outcome: ThreeChoiceEvaluation.Outcome
        let token: String

        var testDescription: String { token }
    }

    struct ProgressiveOutcomeToken: Sendable, CustomTestStringConvertible {
        let outcome: ProgressiveFlashcardEvaluation.Outcome
        let token: String

        var testDescription: String { token }
    }

    struct ProgressiveTransitionToken: Sendable, CustomTestStringConvertible {
        let transition: ProgressiveFlashcardEvaluation.Transition
        let token: String

        var testDescription: String { token }
    }
}
