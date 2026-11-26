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
- Packages are built for iOS 18 and macOS (macOS is there so `scripts/verify packages` can test them without a simulator).
- Bundle id `dev.purlay.ios`; tests `dev.purlay.ios.tests` and `dev.purlay.ios.uitests`.

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
- A failure shown to a person is a sentence written for them. The server's or the platform's description is not one (see TD-004).
- An empty `catch`, a swallowed `try?` that hides a failure the person should know about, and a silent fallback are not allowed.
  A `try?` is acceptable only for work whose failure changes nothing (cancelling a sleep).

## Tests

- New behaviour comes with a test; a bug fix starts with a failing regression test. Test behaviour, not implementation.
- Logic is tested in the package that owns it, on macOS, without a simulator. The app target's tests cover wiring only.
- Replace only the network, the Keychain and the clock. `PurlayTestSupport` (from `purlay-swift`) holds the fakes.
- A screen that shows data has loading, error and empty states, accessibility labels, and a guard against a double submit.
- The sign-in UI tests need a server and skip themselves without one ([getting started](../development/getting-started.md)).

## Concurrency and state

- `@MainActor` for everything that touches a view or the model; `Sendable` across boundaries.
- A bridge from a callback API to async code answers exactly once (see `Answer` in `WebAuthSession.swift`).
- State that outlives a launch is in the Keychain (the session) or the defaults (preferences, the data owner); nothing else is
  persisted yet. After a restart the session and drafts are found again; in-flight sends are the engine's outbox.

## Privacy and logging

- The session cookie lives only in the Keychain. No secret in `Info.plist`, defaults or source (gitleaks checks the history).
- Debug-only development shortcuts (`PURLAY_DEV_SERVER`, `PURLAY_DEV_SESSION`, `PURLAY_DEV_RESET`) are compiled out of Release.
- No personal data in logs; there is no logging code yet, so the first use adds `os.Logger` with `privacy: .private`.

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
| Copying a shared file and editing the copy | change it at its owner ([runbook](../runbooks/change-a-shared-file.md)) | `scripts/check-shared-files` |
