import Foundation

/// Content displayed as one side of a flashcard.
public struct FlashcardContent: Codable, Sendable, Hashable {
    /// Optional text supplied by the host.
    public let text: String?

    /// Optional opaque reference to a host-owned asset.
    public let assetReference: String?

    /// Creates text-only flashcard content.
    ///
    /// - Parameter text: Nonempty text presented by the host.
    /// - Throws: ``FlashcardContentError/emptyText`` when `text` is empty.
    public init(text: String) throws {
        try self.init(text: text, assetReference: nil)
    }

    /// Creates asset-only flashcard content.
    ///
    /// - Parameter assetReference: A nonempty opaque identifier resolved by the host.
    /// - Throws: ``FlashcardContentError/emptyAssetReference`` when `assetReference` is empty.
    public init(assetReference: String) throws {
        try self.init(text: nil, assetReference: assetReference)
    }

    /// Creates content containing text, an asset reference, or both.
    ///
    /// - Parameters:
    ///   - text: Optional nonempty text presented by the host.
    ///   - assetReference: Optional nonempty opaque identifier resolved by the host.
    /// - Throws: ``FlashcardContentError`` when no representation is supplied or a supplied value is empty.
    public init(text: String?, assetReference: String?) throws {
        guard text != nil || assetReference != nil else {
            throw FlashcardContentError.missingRepresentation
        }
        if text?.isEmpty == true {
            throw FlashcardContentError.emptyText
        }
        if assetReference?.isEmpty == true {
            throw FlashcardContentError.emptyAssetReference
        }
        self.text = text
        self.assetReference = assetReference
    }

    /// Decodes content while preserving the same invariants enforced by public initializers.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let text = try container.decodeIfPresent(String.self, forKey: .text)
        let assetReference = try container.decodeIfPresent(String.self, forKey: .assetReference)
        try self.init(text: text, assetReference: assetReference)
    }
}

/// Validation failures produced while creating flashcard content.
public enum FlashcardContentError: Error, Sendable, Equatable {
    /// Neither text nor an asset reference was supplied.
    case missingRepresentation

    /// Supplied text was empty.
    case emptyText

    /// The supplied asset reference was empty.
    case emptyAssetReference
}
