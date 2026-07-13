# Changelog

All notable changes to this project are documented in this file.

## [0.6.0] - 2026-07-13

### Added

**Cashu Wallet (new)**
- Account-scoped wallet with multi-mint management and per-mint balances
- Wallet recovery flow with status feedback and retry on refresh
- Ecash token send and receive
- Lightning receive with automatic quote polling
- Lightning pay with quote persistence, expired-quote recovery, and execution guards

**Push notifications**
- Nostr relay-based push notifications (NIP-9A)
- Migrated Android push from Firebase/FCM to UnifiedPush
- Improved iOS VoIP/APNs push (login retry, Apple compliance)

### Changed
- Refactored networking layer (connect scheduling, timeout, auth state, request tracking)
- Hardened app lifecycle and call handling (NIP-AC)
- Upgraded build toolchain to Flutter 3.38.10 / Dart 3.10

### Fixed
- Android: full-screen incoming-call intent and tablet orientation
- iOS: VoIP push compliance and push-token upload
