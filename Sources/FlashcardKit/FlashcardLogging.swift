import AppLogger

enum FlashcardLogging {
    static let emoji = "🃏"
    static let subsystem = "com.thatfactory.flashcardkit"

    static func sessionCreated(rounds: Int) {
        log("session created | rounds=\(rounds)")
    }

    static func sessionRejected(reason: String) {
        log(level: .error, "session rejected | reason=\(reason)")
    }

    static func responseAccepted(outcome: ThreeChoiceEvaluation.Outcome, completed: Int, total: Int) {
        log("response accepted | outcome=\(outcome.token), completed=\(completed), total=\(total)")
    }

    static func responseRejected(reason: String) {
        log(level: .error, "response rejected | reason=\(reason)")
    }

    static func progressiveSessionCreated(cards: Int) {
        log(progressiveSessionCreatedMessage(cards: cards))
    }

    static func progressiveSessionRejected(reason: String) {
        log(level: .error, progressiveSessionRejectedMessage(reason: reason))
    }

    static func progressiveAttemptAccepted(
        outcome: ProgressiveFlashcardEvaluation.Outcome,
        transition: ProgressiveFlashcardEvaluation.Transition,
        completedCards: Int,
        selectedCards: Int,
        generatedAttempts: Int
    ) {
        log(
            progressiveAttemptAcceptedMessage(
                outcome: outcome,
                transition: transition,
                completedCards: completedCards,
                selectedCards: selectedCards,
                generatedAttempts: generatedAttempts
            ))
    }

    static func progressiveAttemptRejected(reason: String) {
        log(level: .error, progressiveAttemptRejectedMessage(reason: reason))
    }

    static func progressiveSessionCompleted(cards: Int, attempts: Int) {
        log(progressiveSessionCompletedMessage(cards: cards, attempts: attempts))
    }

    static func progressiveAttemptAcceptedMessage(
        outcome: ProgressiveFlashcardEvaluation.Outcome,
        transition: ProgressiveFlashcardEvaluation.Transition,
        completedCards: Int,
        selectedCards: Int,
        generatedAttempts: Int
    ) -> String {
        "progressive attempt accepted | outcome=\(outcome.token), transition=\(transition.token), completed=\(completedCards), selected=\(selectedCards), attempts=\(generatedAttempts)"
    }

    static func progressiveAttemptRejectedMessage(reason: String) -> String {
        "progressive attempt rejected | reason=\(reason)"
    }

    static func progressiveSessionCompletedMessage(cards: Int, attempts: Int) -> String {
        "progressive session completed | cards=\(cards), attempts=\(attempts)"
    }

    static func progressiveSessionCreatedMessage(cards: Int) -> String {
        "progressive session created | cards=\(cards)"
    }

    static func progressiveSessionRejectedMessage(reason: String) -> String {
        "progressive session rejected | reason=\(reason)"
    }

    static func formatted(_ message: String) -> String {
        "\(emoji) \(message)"
    }

    private static func log(level: AppLogLevel = .debug, _ message: String) {
        AppLogger(subsystem: subsystem, category: "session").log(level: level, formatted(message))
    }
}

extension ProgressiveFlashcardEvaluation.Outcome {
    var token: String {
        switch self {
        case .correct: "correct"
        case .expired: "expired"
        case .incorrect: "incorrect"
        }
    }
}

extension ProgressiveFlashcardEvaluation.Transition {
    var token: String {
        switch self {
        case .completed: "completed"
        case .promoted: "promoted"
        case .retained: "retained"
        }
    }
}

extension ThreeChoiceEvaluation.Outcome {
    var token: String {
        switch self {
        case .correct: "correct"
        case .incorrect: "incorrect"
        case .expired: "expired"
        }
    }
}
