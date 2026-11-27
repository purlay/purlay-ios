# Requirements: Purlay for iOS

> Last updated: 2026-11-26 · Vision: [vision.md](vision.md)

Statuses: Draft, Approved, In progress, Done, Cancelled. Priorities: MVP, Next, Maybe. "Engine" means the code is in
`purlay-swift` (`PurlayKit`) and its tests live there (`Tests/PurlayKitTests/AppModelTests.swift`); the iOS screen is the app's part.

## Functional requirements

| ID | Requirement | Acceptance criteria (Given / When / Then) | Priority | Status | Spec |
|----|-------------|-------------------------------------------|----------|--------|------|
| FR-001 | Launch and handshake | Given no stored session, when the app launches, then it asks the server who it is and shows the sign-in screen. Test: engine "at launch with no session kept…"; UI `testTheServersSignInPageOpensAndCancellingReturnsToSignedOut` (needs a server) | MVP | Done | — |
| FR-002 | Say what stands between the app and the server | Given the server is unreachable, is not a Purlay server, is rate-limiting this address, needs a newer app, or is older than the app supports, when the app checks it, then a problem screen shows and nothing else is asked, in words for a person (never the case's description or the server's own text), with a Try Again button that asks once however fast it is tapped. Tests: engine "a server that cannot be reached, is not a Purlay server…", "…needs a newer app, and one older…"; app `RootScreenTests.problems`, `retry`, `unusableAddress` | MVP | Done | — |
| FR-003 | Sign in through the system browser | Given the signed-out screen, when the person taps Sign in, then the server's page opens in the system browser session; and when they approve, the app exchanges the one-time code (PKCE) and reaches the signed-in screen; and when they close the page, nothing is said and they stay signed out; and when the server refuses the code, that is said and they can try again. Tests: engine "closing the page ends it quietly…", "a code the server does not know is said…"; UI sign-in test | MVP | Done | — |
| FR-004 | Resume a stored session | Given a session kept in the Keychain, when the app launches, then the person goes straight to their workspace without signing in; and given the session ended while the app was away, then that is said and they sign in again. Tests: engine "with a session kept the person goes straight…", "a session that ended while the app was away…"; UI `testAStoredSessionOpensTheSignedInScreen` (needs a server) | MVP | Done | — |
| FR-005 | Identify as an iOS client | Given any request or socket upgrade, then it carries `X-Purlay-Client: ios/<version> contract/<n>`, so the server labels the session `Purlay for iOS/…`. Tests: `EnvironmentTests.platform`; engine `ClientHeaderTests` | MVP | Done | — |
| FR-006 | Development server in Debug only | Given a Debug build and `PURLAY_DEV_SERVER`, when the app launches, then it talks to that server, plain HTTP allowed for a local address; and given a Release build, then it talks only to the hosted address over HTTPS with App Transport Security strict. Tests: `ServerChoiceTests` (both kinds of build), `DevelopmentSessionTests`; the strict ATS is held by `scripts/enforcement` (no exception outside the Debug configuration) | MVP | Done | — |
| FR-007 | Show only the modules a workspace may use | Given a registry of features, when the workspace allows a set of module ids, then the features of those ids are shown in the registry's order; an id the build does not know is ignored; a core-only workspace shows the empty shell. Tests: `ModuleRegistryTests` and `WorkspaceShellTests.coreOnly` | MVP | Done | — |
| FR-008 | Floating surfaces in the system's glass | Given a floating control or panel, when it is drawn on iOS 26 or later, then it is Liquid Glass; on iOS 18–25 a system material in the same shape. Test: `SurfaceTests` builds every role and shape; the look itself is checked by eye (Unverified: no snapshot tests yet) | MVP | Done | — |
| FR-020 | Shell: adaptive navigation and workspace switcher | Given a signed-in person, when the app is ready, then enabled modules appear as a tab bar on iPhone and a sidebar in regular width, and the person can switch workspace. Empty, loading and error states exist. Tests: `WorkspaceShellTests` and the seeded `WorkspaceShellUITests` | MVP | Done | — |
| FR-021 | Chat: channel list and message feed | Given a workspace with chat enabled, when the person opens Chat, then channels list with unread state, opening one shows its messages newest at the bottom, older ones load by cursor, and a channel with no messages says so. Retry is available for either page. Tests: `NativeChatUITests` on iPhone and iPad | MVP | Done | — |
| FR-022 | Chat: send a message | Given an open channel, when the person sends text, then it is painted at once and reconciled when the server echoes; a refused or failed send stays visible as failed with retry; space-only text is not sent; a second tap does not send twice. Tests: `NativeComposerUITests` on iPhone and iPad | MVP | Done | — |
| FR-023 | Sign out | Given a signed-in person, when they sign out on this device or everywhere, then the server's session ends, the socket closes, the credential is removed and the sign-in screen shows; with no network this device still signs out and says the server was not told | MVP | Draft | — |
| FR-024 | Turkish and English | Given a device set to Turkish or English, then every sentence on the app's screens is in that language, and the date and the version in a sentence are written for it. Tests: `WordsTests.translated` and `values` (every sentence, both languages); `scripts/enforcement` refuses a catalogue entry with no translation. The shell's own strings come with each new screen | MVP | Done for the screens that exist | — |
| FR-025 | Choose the server | Given the signed-out screen in a Release build, when the person enters their own server's address, then the app accepts only an HTTPS address that answers as a Purlay server, remembers it, and signs in there; a plain-HTTP, malformed or non-Purlay address is refused with a message | Next | Draft | — |
| FR-030 | Closed-app notifications (APNs) | Given a registered device, when a message arrives that the person's Deep Work and quiet hours allow, then the device is notified. Needs a server endpoint and sender first | Next | Draft | — |
| FR-031 | Issues module | Given a workspace with issues enabled, then an Issues section appears through the registry with no change to Chat | Next | Draft | — |
| FR-032 | Inbox, search, profile and settings | Given a signed-in person, then they can read their inbox, search, and edit their profile and settings, as the web client can | Next | Draft | — |

## Non-functional requirements

| ID | Area | Applies? | Target | Verified by |
|----|------|----------|--------|-------------|
| NFR-PERF | Performance budget | Yes | Cold load to an interactive channel, warm cache, under 1.5 s; own message painted in under 16 ms and never awaiting the network; channel switch under 100 ms (the server's budget, PRD §5) | A device measurement once chat ships; not measurable before then |
| NFR-SEC | Security | Yes | No password or web view in the app; session only in the Keychain; PKCE bound to a secret the app keeps; ATS strict in Release; no secret in the repository history; one dependency | `scripts/enforcement`, `scripts/verify security`, engine sign-in tests |
| NFR-PRIV | Privacy (GDPR) | Yes | Holds only the session, preferences and drafts; no analytics or tracking SDK; privacy manifest declares required-reason APIs | `PrivacyManifestTests`; `scripts/enforcement` refuses code that uses a required-reason API the manifest does not declare. The collected-data declaration is A-004 |
| NFR-A11Y | Accessibility | Yes | Every control labelled; Dynamic Type through AX5; Reduce Transparency, Increase Contrast and Reduce Motion honoured; 44 pt targets; VoiceOver | Seen at the largest accessibility size in the simulator (the screens scroll instead of clipping); `performAccessibilityAudit` in the UI tests once there are screens beyond these (Unverified: VoiceOver by ear) |
| NFR-I18N | i18n / l10n | Yes | English and Turkish, string catalogue (`App/Resources/Localizable.xcstrings`) | `WordsTests`, `scripts/enforcement` |
| NFR-OBS | Observability | No: no telemetry by design; the server's logs are the record. Crash reports come from Apple's own channel once distributed | — | — |
| NFR-OFF | Offline / sync | Yes | Sends survive a lost connection (outbox) and replay on reconnect; a cached channel list and recent messages for cold start | Engine tests (outbox, replay); the local store is an open item in the overview |
| NFR-REC | Failure and recovery | Partly | A server problem, an ended session and a failed send are each shown and recoverable; no RPO/RTO: the app holds no source of truth | Engine tests |
| NFR-VER | Versioning and compatibility | Yes | iOS 18 floor; one released `purlay-swift` version; the server's minimum-client gate refuses an app that is too old with a message | `scripts/enforcement`; engine test "an upgrade the server refuses because this app is too old…" |
| NFR-COST | Cost | Yes | CI runs the lanes side by side; a pull request is checked in about two minutes, and a change that slows that needs a reason | CI run times, and the rule in `CONTRIBUTING.md` |
| NFR-SCALE | Scale | No: one person's device | — | — |

## Assumptions

| ID | Assumption | Rationale | Impact | Status |
|----|-----------|-----------|--------|--------|
| A-001 | Bundle id `dev.purlay.ios` and the `purlay://auth` scheme are final | The scheme is fixed by the server (`NATIVE_REDIRECT`); macOS shares it, which is safe because the platforms differ | Medium | Approved |
| A-002 | The first screens are SwiftUI with no UIKit | No measured need yet | Low | Approved |
| A-003 | Local store for cold start is decided by a replay spike before chat ships | Needs measurement against the replay protocol | Medium | Proposed |
| A-004 | The privacy manifest's collected data (name, email address, user id, other user content: linked to the person, for app functionality, never for tracking) is what the hosted server receives from this app. The device's name goes to the server as a session label and is not declared as an identifier | Read from what the app sends: the profile, messages and files, and the sign-in's device name | High for release: the same declaration is made again in App Store Connect and must match | Proposed: the owner confirms before the first submission |
| A-005 | The app icon is the owner's logo on a white square | The logo is light blue on a transparent background and the App Store refuses an icon with transparency; white is also what the macOS icon sits on | Low | Proposed |

## Open questions

| ID | Question | Owner | Target date | Answer / decision |
|----|----------|-------|-------------|-------------------|
| Q-001 | On what licensing basis may a build be released (App Store terms against the AGPL; the CLA relicensing route)? Blocks TD-005 becoming urgent | Owner | Before the first TestFlight | Open (server D-338) |
| Q-002 | What adoption target (weekly active people) and date should the vision carry? | Owner | Before the first release | Open |
| Q-003 | Does the server get a minimum-client gate for `ios` (`MIN_CLIENT_*` names macOS only) before release? Until it does, `Handshake.evaluate` in `purlay-swift` reads the macOS minimum for an iOS app too, so a server that raises the macOS minimum above this app's version refuses it with "needs a newer Purlay" | Owner | Before the first release | Open |
| Q-004 | Is a white background right for the icon (A-005), and should there be a dark and a tinted icon for iOS 18 and later (TD-010)? | Owner | Before the first TestFlight | Open |

## Out of scope

- Mac Catalyst, watchOS and visionOS targets in this repository.
- Dynamic or downloaded modules.
- Client-side message encryption.
- Anything that changes the contract here: it changes in `purlay` first.
