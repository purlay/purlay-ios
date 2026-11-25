# Getting started

1. Install Xcode 27+ and `brew install xcodegen`.
2. `xcodegen generate`, then open `Purlay.xcodeproj` or build with `xcodebuild` (see the README).
3. `scripts/verify` runs every package's tests, builds the app and runs the app's tests.

## Against a local server

In the `purlay` repository: `bun run db:up && bun run db:migrate && bun run dev`. Then launch a Debug build with
`PURLAY_DEV_SERVER=http://localhost:<port>`. Plain HTTP is allowed in Debug builds only.

## Conventions

- Swift 6 language mode, complete strict concurrency, warnings are errors.
- `swift-format` with the repository's `.swift-format` (shared with `purlay-macos` and `purlay-swift`).
- Strings go in `Localizable.xcstrings`, English and Turkish.
- Views read a model and call it; they never reach the network.
- Tests: Swift Testing; only network, Keychain and clock are replaced.
