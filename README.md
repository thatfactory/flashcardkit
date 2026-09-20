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

FlashcardKit is a reusable, UI-agnostic domain package for prompt-and-answer recall activities. Its persistence-friendly card values support one or more ordered recall stages containing text and opaque host-owned asset references without taking ownership of presentation or media resolution.

```swift
let card = Flashcard(
    id: UUID(),
    prompt: try FlashcardContent(text: "der Hund"),
    answer: try FlashcardContent(text: "dog")
)

let stagedCard = try Flashcard(
    id: UUID(),
    stages: [
        FlashcardStage(
            id: FlashcardStageID(rawValue: "definition"),
            prompt: try FlashcardContent(text: "das Haus"),
            answer: try FlashcardContent(text: "house")
        ),
        FlashcardStage(
            id: FlashcardStageID(rawValue: "article"),
            prompt: try FlashcardContent(text: "Haus"),
            answer: try FlashcardContent(text: "das")
        ),
    ]
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

The simple initializer remains the shortest path for one-stage cards. Stage-aware hosts can provide a nonempty ordered sequence with stable, unique stage identifiers. The current `ThreeChoiceSession` continues to use each card's first stage.

Use `ProgressiveFlashcardSession` when a selected card must advance through every ordered stage independently of how the host evaluates it:

```swift
var progressiveSession = try ProgressiveFlashcardSession(
    cards: cards,
    configuration: ProgressiveFlashcardSessionConfiguration(
        seed: 42,
        cardCount: 5
    )
)

if let attempt = progressiveSession.currentAttempt {
    // The host decides how this stage is evaluated.
    let evaluation = try progressiveSession.submit(
        .correct,
        forAttemptID: attempt.id
    )
}
```

Selection is canonicalized by card identity and then seeded-shuffled. Every selected card begins at stage zero. Correct outcomes promote or complete a card; incorrect and expired outcomes retain the current stage. Unfinished cards requeue at the tail, except that a sole unfinished card necessarily repeats immediately. Attempt IDs increase monotonically within the session, and `generatedAttempts` grows with retries and promotions rather than describing a fixed total. Three-choice construction and pronunciation evaluation remain outside the progression engine.

Use `ThreeChoiceRoundPlan` to construct and evaluate one deterministic three-choice interaction from an explicit answer pool:

```swift
let plan = try ThreeChoiceRoundPlan(
    id: 7,
    cardID: card.id,
    prompt: stage.prompt,
    correctAnswer: stage.answer,
    candidates: candidateAnswers,
    seed: 42
)

let round = plan.round
let evaluation = try plan.evaluate(
    .selection(choiceID: round.choices[0].id),
    forRoundID: round.id
)
```

The candidate pool may omit the authoritative correct answer or contain it exactly once; FlashcardKit contributes that answer exactly once to the visible round. Repeated correct-answer candidates and duplicate non-correct candidates are rejected rather than silently deduplicated. The ordered pool and seed determine choice ordering, while round identity is copied through without affecting randomness. Consumers can compose a progressive attempt with this round mechanism, but FlashcardKit does not automatically couple progression to three-choice evaluation.

The session plan is reproducible for identical cards, configuration, and seed. Each round exposes one correct answer and two distinct distractors; a host can submit a selected choice or explicit expiry. Presentation, timers, persistence frameworks, image resolution, vocabulary acquisition, and spaced repetition remain outside the package boundary.

## Installation

Add FlashcardKit to a Swift package and depend on the `FlashcardKit` product:

```swift
.package(url: "https://github.com/thatfactory/flashcardkit", from: "0.2.0")
```

## Documentation

API documentation is published with DocC after a GitHub release. See the [FlashcardKit documentation](https://thatfactory.github.io/flashcardkit/documentation/flashcardkit/).

## Requirements

- Swift 6.4
- Xcode 27
- Apple platform versions shown in the badge above
- Swift Package Manager
