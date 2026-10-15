# Slice 14 pastime content attribution

All Sudoku puzzle packs, Spanish word sets and playing-card rank/suit semantics
shipped under `packages/domain/lib/src/pastimes/` are original fictional Demo
content authored for Memora. They are adult-neutral, culturally respectful and
licensed for distribution with this repository under the project LICENSE.

No third-party game SDK, remote catalogue, downloadable package or external URL
is used. Identifiers in synced records refer only to these reviewed allowlists.

## Playing-card rendering decision (human-review Finding 4)

The `playing_cards` pub package was evaluated for Spider faces and **not
adopted**. Memora renders accessible card faces with Flutter primitives in
`packages/ui/lib/src/user/pastimes/games/playing_card_face.dart` so the Spider
domain engine, persistence, offline contract and licence surface stay
app-owned. Suit marks use standard Unicode symbols plus suit letter/label cues;
colour is never the only suit distinction.
