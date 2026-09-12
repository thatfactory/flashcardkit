import Testing
@testable import FlashcardKit

@Test("The package namespace is available")
func packageNamespaceIsAvailable() {
    _ = FlashcardKit.self
}
