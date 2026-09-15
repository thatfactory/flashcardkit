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

    static func formatted(_ message: String) -> String {
        "\(emoji) \(message)"
    }

    private static func log(level: AppLogLevel = .debug, _ message: String) {
        AppLogger(subsystem: subsystem, category: "session").log(level: level, formatted(message))
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
