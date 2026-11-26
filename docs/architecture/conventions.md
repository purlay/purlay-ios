# Code conventions

Only what is specific to this repository and checkable. A rule held by a tool names the tool; the rest is held by review.

## Tools

| Purpose | Tool | Where |
|---|---|---|
| Format | `swift-format lint --strict` (Xcode's toolchain) | `.swift-format` (owned by `purlay-swift`: 120 columns, 4 spaces, trailing commas) |
| Compiler | Swift 6 mode, complete strict concurrency, warnings are errors | `Config/Base.xcconfig`, each `Package.swift` |
| Decision rules | `scripts/enforcement`, with `--demo` proving each rule refuses its violation | `scripts/enforcement` |
| Secrets | gitleaks over the history | `scripts/verify security`, [ADR 0005](../decisions/0005-verify-entry-point-and-secret-scan.md) |
| Test | Swift Testing; XCUITest for the sign-in only | `Tests/`, `Packages/*/Tests/` |
| Verify | `make verify` (a pull request's lanes); `make verify-all` adds the simulator | `Makefile` over `scripts/verify` |

## Layout and naming

- `App/` is a thin composition root: scenes, the real environment, one screen per phase. What the app does lives in packages.
- One package per concern under `Packages/`; one `Feature<Module>` package per server module, named for the module's id
  ([ADR 0003](../decisions/0003-feature-modules.md)). A file is named after the main type it holds.
- Packages are built for iOS 18 and macOS (macOS is there so `scripts/verify packages` can test them without a simulator). Every
  package states the same macOS number, the one `purlay-swift` requires of whatever depends on it (enforced).
- Bundle id `dev.purlay.ios`; tests `dev.purlay.ios.tests` and `dev.purlay.ios.uitests`.
- The app icon is generated: `scripts/icon` writes `AppIcon.appiconset` from `Design/purlay.svg`. Change the SVG and run the script; never edit the PNG. It is one 1024 by 1024 picture with no alpha channel (the App Store refuses transparency), and `scripts/enforcement` refuses a missing, mis-sized or transparent one.

## Layers

- Views read an `@Observable` model and call it; they never reach the network, the Keychain or the clock. The model is
  `AppModel` from `PurlayKit`; features add their own models beside their views.
- Everything the platform provides (network, Keychain, defaults, browser, files, timers) reaches the model through
  `AppEnvironment`, built in `App/Environment/RealEnvironment.swift`.
- A feature depends on `PurlayModuleAPI`, `PurlayDesign` and `purlay-swift`, never on another feature (enforced). What two
  features both need is declared in `PurlayModuleAPI` first.
- OS-version checks (`#available`, `#unavailable`, `@available`) exist only in `PurlayDesign` (enforced, ADR 0001).
- The only dependency is `purlay-swift`, at one released version stated identically in `project.yml` and every
  `Package.swift` (enforced, [ADR 0002](../decisions/0002-shared-swift-packages.md)). One iOS floor, stated identically in
  `Config/Base.xcconfig`, `project.yml` and every package (enforced).

## Errors

- A server problem is a `ServerProblem` and a phase of the model, never an alert that can be dismissed into a broken state.
- Wire error codes are matched from the generated union; an unknown id or code is ignored or shown generically, never a crash.
- A failure shown to a person is a sentence written for them. The server's or the platform's description is not one, and neither is
  `String(describing:)` of a case. Each `ServerProblem` and `SignInError` case has its own sentence in `App/Root/Words.swift`, matched
  exhaustively, so a new case fails to compile until it has words.
- An empty `catch`, a swallowed `try?` that hides a failure the person should know about, and a silent fallback are not allowed.
  A `try?` is acceptable only for work whose failure changes nothing (cancelling a sleep).

## Tests

- New behaviour comes with a test; a bug fix starts with a failing regression test. Test behaviour, not implementation.
- Logic is tested in the package that owns it, on macOS, without a simulator. The app target's tests cover wiring only.
- Replace only the network, the Keychain, the browser and the clock. The app's tests use the fakes in `Tests/PurlayTests/Fakes.swift`,
  not `PurlayTestSupport` ([ADR 0006](../decisions/0006-app-tests-use-their-own-fakes.md)); packages use `PurlayTestSupport`.
- A screen that shows data has loading, error and empty states, accessibility labels, and a guard against a double submit.
- The sign-in UI tests need a server and skip themselves without one ([getting started](../development/getting-started.md)).

## Concurrency and state

- `@MainActor` for everything that touches a view or the model; `Sendable` across boundaries.
- A bridge from a callback API to async code answers exactly once (see `Answer` in `WebAuthSession.swift`).
- State that outlives a launch is in the Keychain (the session) or the defaults (preferences, the data owner); nothing else is
  persisted yet. After a restart the session and drafts are found again; in-flight sends are the engine's outbox.

## Privacy and logging

- The session cookie lives only in the Keychain. No secret in `Info.plist`, defaults or source (gitleaks checks the history).
- Debug-only development shortcuts (`PURLAY_DEV_SERVER`, `PURLAY_DEV_SESSION`, `PURLAY_DEV_RESET`) are compiled out of Release, and
  what they cannot do is logged, not swallowed. Which server a build talks to is decided in `ServerChoice`, tested for both kinds of build.
- No personal data in logs. Logging is `os.Logger` with the default privacy (`.private` for what is interpolated); the only logging
  today is the development shortcuts'.
- `App/Resources/PrivacyInfo.xcprivacy` declares every required-reason API the code uses (`UserDefaults` today) and the data the server
  is sent; `scripts/enforcement` refuses code that uses one the manifest does not declare. After a `purlay-swift` bump, check its
  release notes for new ones ([runbook](../runbooks/bump-purlay-swift.md)).

## Strings and screens

- Every sentence a person reads is a `LocalizedStringResource` in `App/Root/Words.swift` (a feature package has its own `Words`) and an
  entry in `App/Resources/Localizable.xcstrings`: the English sentence is the key, and Turkish is translated (enforced, with the
  languages read from `knownRegions`). A view never writes a literal sentence.
- A button is built from a `Text` label: `Button(Words.x)` showed English on a Turkish simulator while `Text(Words.x)` did not (enforced).
- A screen is decided from a pure value (`RootScreen`) so each phase is tested without drawing; a tap that must happen once goes
  through a guard that reads the phase (`RootActions`), never a flag in the view.
- A screen that can outgrow the display (a large Dynamic Type size, a long sentence) scrolls instead of clipping.

## Forbidden patterns

| Forbidden | Instead | Why |
|---|---|---|
| `@unchecked Sendable`, `nonisolated(unsafe)`, `try!`, `as!`, `fatalError(` in `App/` or `Packages/` | model the type, throw, or handle the case | enforced; a line may opt out with an `enforcement-allow` comment and its reason |
| Force unwrap `!` and implicitly unwrapped optionals in new code | `guard let`, `if let` | traps on a value the code was handed |
| `#available` outside `PurlayDesign` | a `PurlayDesign` modifier named by role | ADR 0001 |
| A feature importing a feature | `PurlayModuleAPI` | ADR 0003 |
| A second dependency, or a second `purlay-swift` pin | add to `purlay-swift`, or an ADR first | ADR 0002 |
| Lowering strict concurrency, silencing a warning, `// swift-format-ignore` without a reason | fix the cause | the compiler is the first reviewer |
| Editing `Purlay.xcodeproj` | edit `project.yml` and regenerate | the project is generated and ignored |
| Drawing glass by hand | `purlaySurface` | ADR 0001 |
| `Button(Words.x)`, a literal sentence in a view, `String(describing:)` of an error shown to a person | a `Text(Words.x)` label; a sentence in `Words` | the catalogue, and a person is not shown a developer's text |
| Linking `PurlayTestSupport` into `PurlayTests` | the fakes in `Tests/PurlayTests/Fakes.swift` | ADR 0006 |
| Copying a shared file and editing the copy | change it at its owner ([runbook](../runbooks/change-a-shared-file.md)) | `scripts/check-shared-files` |
