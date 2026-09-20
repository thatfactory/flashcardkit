# ``FlashcardKit``

Build deterministic, UI-agnostic recall activities from host-owned prompt-and-answer content.

## Overview

Use ``Flashcard`` to give recall activities stable host-owned identity and one or more ordered ``FlashcardStage`` values. Each stage has a host-authored ``FlashcardStageID``, prompt content, and answer content. ``FlashcardContent`` can carry text, an opaque host-owned asset reference, or both, while preserving a nonempty representation invariant across creation and decoding.

```swift
let card = Flashcard(
    id: UUID(),
    prompt: try FlashcardContent(text: "der Hund"),
    answer: try FlashcardContent(text: "dog")
)
```

The simple initializer constructs one stage with ``FlashcardStageID/primary``. Stage-aware hosts can create a card from a nonempty sequence whose identifiers are unique within that card:

```swift
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
```

Stage order is significant and preserved by `Codable`. ``FlashcardError`` reports missing stages and duplicate stage identifiers. Current ``ThreeChoiceSession`` behavior remains one-stage-compatible by reading each card's first stage.

Use ``ProgressiveFlashcardSession`` to select a deterministic subset of cards and advance each card through all of its ordered stages without coupling progression to the host's response mechanism:

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

The session canonicalizes cards by identity before seeded selection, begins each selected card at stage zero, and gives every presentation opportunity a monotonic session-scoped attempt identity. Correct outcomes promote a card or complete its final stage; incorrect and expired outcomes retain the same stage. Every unfinished card is appended to the queue tail, so it reappears after other unfinished cards. A sole unfinished card necessarily repeats immediately. ``ProgressiveFlashcardProgress/generatedAttempts`` grows as retries and promotions issue new attempts and is not a fixed session total.

``ThreeChoiceSession`` remains a separate finite stage-zero engine. Progressive sessions consume only host-decided correct, incorrect, or expired outcomes; they do not construct choices, evaluate pronunciation, own timers, or assign scores.

The package does not resolve asset references or own presentation, persistence frameworks, vocabulary acquisition, or scheduling policy.

Use ``ThreeChoiceSession`` to create a finite seeded plan with one correct answer and two distinct distractors per round. The host owns any timer and submits either ``ThreeChoiceResponse/selection(choiceID:)`` or ``ThreeChoiceResponse/expired`` against the exact visible round identity.

```swift
var session = try ThreeChoiceSession(
    cards: cards,
    configuration: ThreeChoiceSessionConfiguration(seed: 42)
)

if let round = session.currentRound {
    let evaluation = try session.submit(.expired, forRoundID: round.id)
}
```

FlashcardKit uses a stable internal random algorithm. Identical card sets, configuration, and seed reproduce shuffled plans independently of the host collection's input order; source ordering intentionally preserves input order.
