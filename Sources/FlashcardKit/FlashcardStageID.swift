import Foundation

/// Stable host-authored identity for one recall stage.
public struct FlashcardStageID: RawRepresentable, Codable, Sendable, Hashable {
    /// Conventional identity used by the simple-card compatibility initializer.
    public static let primary = Self(rawValue: "primary")

    /// Host-authored stable value.
    public let rawValue: String

    /// Creates a stage identity from a host-owned stable value.
    ///
    /// - Parameter rawValue: Stable value unique within its card.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
