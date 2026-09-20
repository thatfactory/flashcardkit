public import Foundation

/// Host-authored prompt-and-answer content used by recall activities.
public struct Flashcard: Identifiable, Codable, Sendable, Hashable {
    /// The stable identity supplied by the host.
    public let id: UUID

    /// Ordered recall stages authored by the host.
    public let stages: [FlashcardStage]

    /// Content presented by the first stage.
    ///
    /// This compatibility property preserves the simple-card API. Stage-aware consumers should use ``stages``.
    public var prompt: FlashcardContent {
        stages[0].prompt
    }

    /// Content evaluated as the first stage's answer.
    ///
    /// This compatibility property preserves the simple-card API. Stage-aware consumers should use ``stages``.
    public var answer: FlashcardContent {
        stages[0].answer
    }

    /// Creates a flashcard from validated prompt and answer content.
    ///
    /// - Parameters:
    ///   - id: Stable host-owned identity.
    ///   - prompt: Content presented for recall.
    ///   - answer: Content revealed or evaluated as the answer.
    public init(id: UUID, prompt: FlashcardContent, answer: FlashcardContent) {
        self.id = id
        stages = [FlashcardStage(id: .primary, prompt: prompt, answer: answer)]
    }

    /// Creates a flashcard from one or more ordered recall stages.
    ///
    /// - Parameters:
    ///   - id: Stable host-owned identity.
    ///   - stages: Nonempty ordered stages with unique host-authored identities.
    /// - Throws: ``FlashcardError`` when no stages are supplied or stage identities are duplicated.
    public init(id: UUID, stages: [FlashcardStage]) throws {
        guard !stages.isEmpty else {
            throw FlashcardError.missingStages
        }

        var stageIDs = Set<FlashcardStageID>()
        for stage in stages where !stageIDs.insert(stage.id).inserted {
            throw FlashcardError.duplicateStageID(stage.id)
        }

        self.id = id
        self.stages = stages
    }

    /// Decodes current staged cards and cards encoded by the original simple-card model.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        if let stages = try container.decodeIfPresent([FlashcardStage].self, forKey: .stages) {
            try self.init(id: id, stages: stages)
        } else {
            self.init(
                id: id,
                prompt: try container.decode(FlashcardContent.self, forKey: .prompt),
                answer: try container.decode(FlashcardContent.self, forKey: .answer)
            )
        }
    }

    /// Encodes staged cards while retaining the original representation for simple-card readers.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(stages, forKey: .stages)
        if stages.count == 1 {
            try container.encode(prompt, forKey: .prompt)
            try container.encode(answer, forKey: .answer)
        }
    }

    // MARK: - Private

    private enum CodingKeys: String, CodingKey {
        case answer
        case id
        case prompt
        case stages
    }
}
