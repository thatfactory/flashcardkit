import Foundation
import Testing

@testable import FlashcardKit

@Suite("Three-choice sessions")
struct ThreeChoiceSessionTests {
    @Test("A fixed seed creates a stable three-choice plan")
    func fixedSeedFixture() throws {
        var session = try ThreeChoiceSession(
            cards: cards,
            configuration: ThreeChoiceSessionConfiguration(seed: 42, ordering: .shuffled)
        )

        var rounds: [ThreeChoiceRound] = []
        while let round = session.currentRound {
            rounds.append(round)
            _ = try session.submit(.expired, forRoundID: round.id)
        }

        #expect(rounds.map(\.cardID) == [cardID(3), cardID(1), cardID(4), cardID(2)])
        #expect(
            rounds.map { $0.choices.map(\.content.text) } == [
                ["dog", "book", "cat"],
                ["house", "cat", "book"],
                ["cat", "book", "dog"],
                ["house", "cat", "dog"],
            ])
    }

    @Test("Shuffled sessions ignore source collection order")
    func shuffledInputOrderIndependence() throws {
        let configuration = ThreeChoiceSessionConfiguration(seed: 7)
        let original = try ThreeChoiceSession(cards: cards, configuration: configuration)
        let reversed = try ThreeChoiceSession(cards: cards.reversed(), configuration: configuration)

        #expect(original.currentRound == reversed.currentRound)
    }

    @Test("Source ordering preserves caller order and limits rounds")
    func sourceOrdering() throws {
        let session = try ThreeChoiceSession(
            cards: cards,
            configuration: ThreeChoiceSessionConfiguration(
                seed: 1,
                roundCount: 2,
                ordering: .source
            )
        )

        #expect(session.currentRound?.cardID == cardID(1))
        #expect(session.progress == ThreeChoiceProgress(completedRounds: 0, totalRounds: 2))
    }

    @Test("Every round contains exactly three distinct answers")
    func distinctAnswers() throws {
        let duplicateDefinitionCards = try [
            card(1, prompt: "Haus", answer: "house"),
            card(2, prompt: "Gebäude", answer: "house"),
            card(3, prompt: "Hund", answer: "dog"),
            card(4, prompt: "Katze", answer: "cat"),
        ]
        var session = try ThreeChoiceSession(
            cards: duplicateDefinitionCards,
            configuration: ThreeChoiceSessionConfiguration(seed: 12, ordering: .source)
        )

        while let round = session.currentRound {
            #expect(round.choices.count == 3)
            #expect(Set(round.choices.map(\.content)).count == 3)
            _ = try session.submit(.expired, forRoundID: round.id)
        }
    }

    @Test("Selections and expiry evaluate and advance")
    func evaluationAndProgress() throws {
        var session = try ThreeChoiceSession(
            cards: cards,
            configuration: ThreeChoiceSessionConfiguration(seed: 3, roundCount: 3)
        )

        let first = try #require(session.currentRound)
        let firstCorrectID = try correctChoiceID(in: first, cards: cards)
        let correct = try session.submit(.selection(choiceID: firstCorrectID), forRoundID: first.id)
        #expect(correct.outcome == .correct)
        #expect(correct.correctChoiceID == firstCorrectID)

        let second = try #require(session.currentRound)
        let secondCorrectID = try correctChoiceID(in: second, cards: cards)
        let incorrectID = try #require(second.choices.first { $0.id != secondCorrectID }?.id)
        let incorrect = try session.submit(.selection(choiceID: incorrectID), forRoundID: second.id)
        #expect(incorrect.outcome == .incorrect)
        #expect(incorrect.selectedChoiceID == incorrectID)

        let third = try #require(session.currentRound)
        let expired = try session.submit(.expired, forRoundID: third.id)
        #expect(expired.outcome == .expired)
        #expect(expired.selectedChoiceID == nil)
        #expect(session.progress == ThreeChoiceProgress(completedRounds: 3, totalRounds: 3))
        #expect(session.isComplete)
        #expect(session.currentRound == nil)
    }

    @Test("Rejected responses preserve session state")
    func rejectedResponsesDoNotAdvance() throws {
        var session = try ThreeChoiceSession(
            cards: cards,
            configuration: ThreeChoiceSessionConfiguration(seed: 5)
        )
        let round = try #require(session.currentRound)
        let progress = session.progress

        #expect(throws: ThreeChoiceSessionError.staleRound(expected: round.id, received: 99)) {
            try session.submit(.expired, forRoundID: 99)
        }
        #expect(session.currentRound == round)
        #expect(session.progress == progress)

        #expect(throws: ThreeChoiceSessionError.invalidChoice(99)) {
            try session.submit(.selection(choiceID: 99), forRoundID: round.id)
        }
        #expect(session.currentRound == round)
        #expect(session.progress == progress)
    }

    @Test("Submission after completion fails without changing progress")
    func submissionAfterCompletion() throws {
        var session = try ThreeChoiceSession(
            cards: cards,
            configuration: ThreeChoiceSessionConfiguration(seed: 8, roundCount: 1)
        )
        let round = try #require(session.currentRound)
        _ = try session.submit(.expired, forRoundID: round.id)

        #expect(throws: ThreeChoiceSessionError.sessionComplete) {
            try session.submit(.expired, forRoundID: round.id)
        }
        #expect(session.progress == ThreeChoiceProgress(completedRounds: 1, totalRounds: 1))
    }

    @Test("Identical sessions replay the same response script")
    func deterministicReplay() throws {
        let configuration = ThreeChoiceSessionConfiguration(seed: 99)
        var first = try ThreeChoiceSession(cards: cards, configuration: configuration)
        var second = try ThreeChoiceSession(cards: cards, configuration: configuration)

        while let firstRound = first.currentRound, let secondRound = second.currentRound {
            #expect(firstRound == secondRound)
            let choiceID = firstRound.choices[1].id
            let firstEvaluation = try first.submit(.selection(choiceID: choiceID), forRoundID: firstRound.id)
            let secondEvaluation = try second.submit(.selection(choiceID: choiceID), forRoundID: secondRound.id)
            #expect(firstEvaluation == secondEvaluation)
            #expect(first.progress == second.progress)
        }

        #expect(first.isComplete)
        #expect(second.isComplete)
    }

    @Test("Session values satisfy their declared protocols")
    func protocolConformance() throws {
        let session = try ThreeChoiceSession(
            cards: cards,
            configuration: ThreeChoiceSessionConfiguration(seed: 1)
        )
        let round = try #require(session.currentRound)
        let response = ThreeChoiceResponse.expired

        requireSendable(session)
        requireValueContract(round)
        requireValueContract(round.choices[0])
        requireValueContract(session.progress)
        requireSendableAndHashable(response)
    }

    @Test("Public session values survive Codable round trips")
    func codableRoundTrips() throws {
        let configuration = ThreeChoiceSessionConfiguration(seed: 44, roundCount: 1)
        var session = try ThreeChoiceSession(cards: cards, configuration: configuration)
        let round = try #require(session.currentRound)
        let evaluation = try session.submit(.expired, forRoundID: round.id)

        try expectRoundTrip(configuration)
        try expectRoundTrip(round)
        try expectRoundTrip(evaluation)
        try expectRoundTrip(session.progress)
    }

    private var cards: [Flashcard] {
        get throws {
            try [
                card(1, prompt: "Haus", answer: "house"),
                card(2, prompt: "Hund", answer: "dog"),
                card(3, prompt: "Katze", answer: "cat"),
                card(4, prompt: "Buch", answer: "book"),
            ]
        }
    }

    private func card(_ id: Int, prompt: String, answer: String) throws -> Flashcard {
        Flashcard(
            id: cardID(id),
            prompt: try FlashcardContent(text: prompt),
            answer: try FlashcardContent(text: answer)
        )
    }

    private func cardID(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }

    private func correctChoiceID(in round: ThreeChoiceRound, cards: [Flashcard]) throws -> Int {
        let answer = try #require(cards.first { $0.id == round.cardID }?.answer)
        return try #require(round.choices.first { $0.content == answer }?.id)
    }

    private func requireSendable<Value: Sendable>(_ value: Value) {
        _ = value
    }

    private func requireValueContract<Value: Codable & Sendable & Hashable>(_ value: Value) {
        _ = value
    }

    private func requireSendableAndHashable<Value: Sendable & Hashable>(_ value: Value) {
        _ = value
    }

    private func expectRoundTrip<Value: Codable & Equatable>(_ value: Value) throws {
        let data = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Value.self, from: data) == value)
    }
}
