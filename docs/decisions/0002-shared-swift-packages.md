# 0002. Share Contract, Kit and Tokens through `purlay-swift`

Status: accepted, 2026-11-25 (supersedes the interim plan of consuming `purlay-macos` packages directly)

**Context.** About 36,000 lines of tested Swift (wire types, sign-in, transport, realtime, outbox, tokens) existed
in `purlay-macos`, none of it AppKit-dependent. Two Apple apps now need it, and a third client (Android) will not.

**Decision.** The code lives in its own repository, `purlay-swift`: one package, four products
(`PurlayContract`, `PurlayTokens`, `PurlayKit`, `PurlayTestSupport`), with the contract pin and the generator.
Apps pin a released version (`from: 0.1.0`).

**Rejected.** *Copying into each app:* sign-in and realtime drift. *Consuming `purlay-macos` packages:* couples
iOS to the Mac app's release cadence. *Kotlin Multiplatform:* trades platform-native feel for a shared runtime.

**Consequences.** A change to the Kit is made in `purlay-swift` and picked up here by version. `purlay-macos` consumes
the same package (purlay/purlay-macos#9).
