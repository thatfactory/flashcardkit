import Foundation
import Testing

@testable import FlashcardKit

@Suite("Flashcard models")
struct FlashcardModelTests {
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

        #expect(decoded == card)
        #expect(Set([card, decoded]).count == 1)
    }

    @Test("Decoding enforces content invariants")
    func decodingValidation() {
        #expect(throws: FlashcardContentError.missingRepresentation) {
            try JSONDecoder().decode(FlashcardContent.self, from: Data("{}".utf8))
        }
    }

    @Test("Public models satisfy persistence and concurrency contracts")
    func protocolConformance() throws {
        let content = try FlashcardContent(text: "Haus")
        let card = Flashcard(id: UUID(), prompt: content, answer: content)

        requireValueContract(content)
        requireValueContract(card)
    }

    private func requireValueContract<Value: Codable & Sendable & Hashable>(_ value: Value) {
        _ = value
    }
}

extension FlashcardModelTests {
    struct InvalidContent: Sendable, CustomTestStringConvertible {
        let text: String?
        let assetReference: String?
        let error: FlashcardContentError

        var testDescription: String {
            "text=\(text ?? "nil"), assetReference=\(assetReference ?? "nil")"
        }
    }
}
