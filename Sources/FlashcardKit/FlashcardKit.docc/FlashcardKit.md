# ``FlashcardKit``

Build deterministic, UI-agnostic recall activities from host-owned prompt-and-answer content.

## Overview

Use ``Flashcard`` to give recall activities stable host-owned identity, prompt content, and answer content. ``FlashcardContent`` can carry text, an opaque host-owned asset reference, or both, while preserving a nonempty representation invariant across creation and decoding.

```swift
let card = Flashcard(
    id: UUID(),
    prompt: try FlashcardContent(text: "der Hund"),
    answer: try FlashcardContent(text: "dog")
)
```

The package does not resolve asset references or own presentation, persistence frameworks, vocabulary acquisition, or scheduling policy.
