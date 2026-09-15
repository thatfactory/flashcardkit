<p align="center">
  <a href="https://developer.apple.com/swift/"><img alt="Swift Version" src="https://img.shields.io/badge/Swift-6.4-ea7a50.svg?logo=swift&logoColor=white"></a>
  <a href="https://developer.apple.com/xcode/"><img alt="Xcode Version" src="https://img.shields.io/badge/Xcode-27-50ace8.svg?logo=xcode&logoColor=white"></a>
  <a href="https://forums.swift.org/t/introducing-anyappleos/85728"><img alt="Platforms" src="https://img.shields.io/badge/AnyAppleOS-26%2B-lightgrey.svg?logo=apple&logoColor=white"></a>
  <a href="https://developer.apple.com/documentation/xcode/swift-packages"><img alt="SPM" src="https://img.shields.io/badge/SPM-ready-b68f6a.svg?logo=gitlfs&logoColor=white"></a>
  <a href="https://thatfactory.github.io/flashcardkit/documentation/flashcardkit/"><img alt="DocC" src="https://img.shields.io/badge/DocC-documentation-0288D1.svg?logo=bookstack&logoColor=white"></a>
  <a href="https://en.wikipedia.org/wiki/MIT_License"><img alt="License" src="https://img.shields.io/badge/License-MIT-67ac5b.svg?logo=googledocs&logoColor=white"></a>
  <a href="https://github.com/thatfactory/flashcardkit/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/thatfactory/flashcardkit/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/thatfactory/flashcardkit/actions/workflows/release.yml"><img alt="Release" src="https://github.com/thatfactory/flashcardkit/actions/workflows/release.yml/badge.svg"></a>
</p>

# FlashcardKit

FlashcardKit is a reusable, UI-agnostic domain package for prompt-and-answer recall activities. Its persistence-friendly card values support text and opaque host-owned asset references without taking ownership of presentation or media resolution.

```swift
let card = Flashcard(
    id: UUID(),
    prompt: try FlashcardContent(text: "der Hund"),
    answer: try FlashcardContent(text: "dog")
)

var session = try ThreeChoiceSession(
    cards: cards,
    configuration: ThreeChoiceSessionConfiguration(seed: 42, roundCount: 5)
)

if let round = session.currentRound {
    let evaluation = try session.submit(
        .selection(choiceID: round.choices[0].id),
        forRoundID: round.id
    )
}
```

The session plan is reproducible for identical cards, configuration, and seed. Each round exposes one correct answer and two distinct distractors; a host can submit a selected choice or explicit expiry. Presentation, timers, persistence frameworks, image resolution, vocabulary acquisition, and spaced repetition remain outside the package boundary.

## Documentation

API documentation is published with DocC after a GitHub release. See the [FlashcardKit documentation](https://thatfactory.github.io/flashcardkit/documentation/flashcardkit/).

## Requirements

- Swift 6.4
- Xcode 27
- Apple platform versions shown in the badge above
- Swift Package Manager
