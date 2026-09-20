# Changelog

All notable changes to FlashcardKit are documented here.

## 0.2.0 — 2026-09-20

### Added

- Added ordered multi-stage flashcards while preserving the original single-stage initializer and payload compatibility.
- Added deterministic progressive sessions that promote correct cards, retain missed stages, requeue unfinished cards, and complete after every selected card's final stage.
- Added a reusable deterministic three-choice round plan with explicit candidate pools, strict validation, answer evaluation, and privacy-safe lifecycle diagnostics.

### Changed

- Refactored the existing finite `ThreeChoiceSession` to share the reusable round planner without changing its public behavior or seeded fixtures.
- Adopted Agent Guidelines `0.0.34` while retaining the strict Swift 6 package compiler-settings baseline.

## 0.1.1 — 2026-09-19

### Changed

- Adopted Agent Guidelines `0.0.33` and the Swift package compiler-settings baseline.
- Declared Swift 6, warnings as errors, and the required upcoming language features for every package target.
- Made imports and existential types explicit where required by the stricter compiler policy without intentionally changing runtime behavior.


## 0.1.0 - 2026-09-15

### Added

- Added deterministic finite three-choice sessions with seeded ordering, distinct distractors, explicit expiry, answer evaluation, progress, typed validation, and stale-round protection.
- Added validated, persistence-friendly `Flashcard` and `FlashcardContent` public models for text and opaque host-owned asset references.
- Bootstrapped the Swift package, DocC catalog, CI/CD workflows, shared AgentGuidelines integration, and repository policy.
