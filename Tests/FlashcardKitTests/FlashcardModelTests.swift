import Foundation
import Testing

@testable import FlashcardKit

@Suite("Flashcard models")
struct FlashcardModelTests {
    @Test("Simple-card initializer creates one primary stage")
    func simpleCardCompatibility() throws {
        let prompt = try FlashcardContent(text: "Haus")
        let answer = try FlashcardContent(text: "house")

        let card = Flashcard(id: UUID(), prompt: prompt, answer: answer)

        #expect(card.stages == [FlashcardStage(id: .primary, prompt: prompt, answer: answer)])
        #expect(card.prompt == prompt)
        #expect(card.answer == answer)
    }

    @Test("Multi-stage cards preserve significant stage order through Codable")
    func orderedStagesRoundTrip() throws {
        let definition = FlashcardStage(
            id: FlashcardStageID(rawValue: "definition"),
            prompt: try FlashcardContent(text: "Haus"),
            answer: try FlashcardContent(text: "house")
        )
        let article = FlashcardStage(
            id: FlashcardStageID(rawValue: "article"),
            prompt: try FlashcardContent(text: "Haus"),
            answer: try FlashcardContent(text: "das")
        )
        let card = try Flashcard(id: UUID(), stages: [definition, article])

        let encoded = try JSONEncoder().encode(card)
        let decoded = try JSONDecoder().decode(Flashcard.self, from: encoded)

        #expect(decoded == card)
        #expect(decoded.stages.map(\.id.rawValue) == ["definition", "article"])
        #expect(decoded.prompt == definition.prompt)
        #expect(decoded.answer == definition.answer)
    }

    @Test("Cards reject an empty stage sequence")
    func emptyStages() {
        #expect(throws: FlashcardError.missingStages) {
            try Flashcard(id: UUID(), stages: [])
        }
    }

    @Test("Cards reject duplicate stage identities")
    func duplicateStageIDs() throws {
        let identity = FlashcardStageID(rawValue: "definition")
        let content = try FlashcardContent(text: "Haus")
        let stage = FlashcardStage(id: identity, prompt: content, answer: content)

        #expect(throws: FlashcardError.duplicateStageID(identity)) {
            try Flashcard(id: UUID(), stages: [stage, stage])
        }
    }

    @Test("Content supports text, assets, and their combination")
    func representations() throws {
        #expect(try FlashcardContent(text: "Haus").text == "Haus")
        #expect(try FlashcardContent(assetReference: "asset-1").assetReference == "asset-1")

        let combined = try FlashcardContent(text: "Haus", assetReference: "asset-1")
        #expect(combined.text == "Haus")
        #expect(combined.assetReference == "asset-1")
    }

    @Test(
        "Content rejects invalid representations",
        arguments: [
            InvalidContent(text: nil, assetReference: nil, error: .missingRepresentation),
            InvalidContent(text: "", assetReference: nil, error: .emptyText),
            InvalidContent(text: nil, assetReference: "", error: .emptyAssetReference),
            InvalidContent(text: "Haus", assetReference: "", error: .emptyAssetReference),
        ]
    )
    func invalidRepresentations(example: InvalidContent) {
        #expect(throws: example.error) {
            try FlashcardContent(text: example.text, assetReference: example.assetReference)
        }
    }

    @Test("Card identity and content survive a Codable round trip")
    func codableRoundTrip() throws {
        let card = Flashcard(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            prompt: try FlashcardContent(text: "Haus"),
            answer: try FlashcardContent(text: "house", assetReference: "house-image")
        )

        let encoded = try JSONEncoder().encode(card)
        let decoded = try JSONDecoder().decode(Flashcard.self, from: encoded)
        let legacyDecoded = try JSONDecoder().decode(LegacyFlashcard.self, from: encoded)

        #expect(decoded == card)
        #expect(Set([card, decoded]).count == 1)
        #expect(legacyDecoded.id == card.id)
        #expect(legacyDecoded.prompt == card.prompt)
        #expect(legacyDecoded.answer == card.answer)
    }

    @Test("Decoding enforces content invariants")
    func decodingValidation() {
        #expect(throws: FlashcardContentError.missingRepresentation) {
            try JSONDecoder().decode(FlashcardContent.self, from: Data("{}".utf8))
        }
    }

    @Test("Decoding accepts the original simple-card representation")
    func legacyCardDecoding() throws {
        let legacy = LegacyFlashcard(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            prompt: try FlashcardContent(text: "Haus"),
            answer: try FlashcardContent(text: "house")
        )

        let decoded = try JSONDecoder().decode(
            Flashcard.self,
            from: JSONEncoder().encode(legacy)
        )

        #expect(decoded.id == legacy.id)
        #expect(decoded.stages.count == 1)
        #expect(decoded.stages[0].id == .primary)
        #expect(decoded.prompt == legacy.prompt)
        #expect(decoded.answer == legacy.answer)
    }

    @Test("Decoding rejects an empty stage sequence")
    func emptyStagesDecoding() throws {
        let payload = StagedFlashcardPayload(id: UUID(), stages: [])

        #expect(throws: FlashcardError.missingStages) {
            try JSONDecoder().decode(
                Flashcard.self,
                from: JSONEncoder().encode(payload)
            )
        }
    }

    @Test("Decoding rejects duplicate stage identities")
    func duplicateStageIDsDecoding() throws {
        let identity = FlashcardStageID(rawValue: "definition")
        let content = try FlashcardContent(text: "Haus")
        let stage = FlashcardStage(id: identity, prompt: content, answer: content)
        let payload = StagedFlashcardPayload(id: UUID(), stages: [stage, stage])

        #expect(throws: FlashcardError.duplicateStageID(identity)) {
            try JSONDecoder().decode(
                Flashcard.self,
                from: JSONEncoder().encode(payload)
            )
        }
    }

    @Test("Public models satisfy persistence and concurrency contracts")
    func protocolConformance() throws {
        let content = try FlashcardContent(text: "Haus")
        let card = Flashcard(id: UUID(), prompt: content, answer: content)
        let stage = FlashcardStage(id: .primary, prompt: content, answer: content)
        let stageID = FlashcardStageID(rawValue: "definition")

        requireValueContract(content)
        requireValueContract(card)
        requireValueContract(stage)
        requireValueContract(stageID)
    }

    private func requireValueContract<Value: Codable & Sendable & Hashable>(_ value: Value) {
        _ = value
    }
}

extension FlashcardModelTests {
    struct LegacyFlashcard: Codable {
        let id: UUID
        let prompt: FlashcardContent
        let answer: FlashcardContent
    }

    struct StagedFlashcardPayload: Codable {
        let id: UUID
        let stages: [FlashcardStage]
    }

    struct InvalidContent: Sendable, CustomTestStringConvertible {
        let text: String?
        let assetReference: String?
        let error: FlashcardContentError

        var testDescription: String {
            "text=\(text ?? "nil"), assetReference=\(assetReference ?? "nil")"
        }
    }
}
