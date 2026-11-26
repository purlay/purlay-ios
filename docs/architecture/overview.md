# Purlay for iOS — Architecture

What the code is today, and where it is going. What is built is stated plainly; what is only planned says so.

## 1. Goals and constraints

- **Deployment target iOS 18, built with the iOS 27 SDK (Xcode 27).** Liquid Glass is the primary design from iOS 26;
  iOS 18–25 get a system material in the same shape, behind one availability seam (§4), never a second hand-built design
  ([ADR 0001](../decisions/0001-deployment-target-and-design-language.md)).
- **The server's shape is the app's shape.** Purlay is a core plus modules (chat, issues; more to come). The app is a core
  plus one feature package per server module, shown only where the server runs the module and the workspace may use it; an id
  the app does not know is ignored ([ADR 0003](../decisions/0003-feature-modules.md)).
- **The contract has one home.** Wire types are generated in `purlay-swift` from the server's contract bundle and never
  written by hand ([ADR 0004](../decisions/0004-contract-single-source.md)).
- Swift 6 language mode, complete strict concurrency, warnings are errors, `@Observable` and SwiftUI by default. UIKit only
  where measured to be necessary; today it appears only where a system API asks for it (the sign-in sheet's window anchor,
  the device name).

## 2. What exists

```
purlay-ios
├── App/                    composition root: @main, RealEnvironment, WebAuthSession, RootView
├── Packages/
│   ├── PurlayModuleAPI     FeatureModule, ModuleID, ModuleRegistry
│   └── PurlayDesign        purlaySurface(_:in:): the one OS-version seam
└── Tests/                  PurlayTests (unit), PurlayUITests (sign-in against a real server)
        │ pins one released version of
        ▼
purlay-swift  →  PurlayContract · PurlayTokens · PurlayKit · PurlayTestSupport
```

| Unit | Owns | Depends on |
|---|---|---|
| `App` | scenes, the real environment (Keychain, defaults, URLSession, system browser, files), the screen for each phase of `AppModel` | `PurlayKit`, `PurlayContract`, `PurlayTokens`, both local packages |
| `PurlayModuleAPI` | the `FeatureModule` protocol (id, title, symbol, root view), `ModuleID` (a string, so an unknown id survives decoding), `ModuleRegistry` (filters by the ids the workspace allows, keeps the registry's order) | nothing |
| `PurlayDesign` | `SurfaceRole` and `purlaySurface`: Liquid Glass from iOS 26, `Material` before | `PurlayTokens` |
| `purlay-swift` (external) | wire types, tokens, `AppModel` and the engine (sign-in, transport, realtime with replay, outbox, uploads), test support | the pinned contract bundle |

Rules, each held by `scripts/enforcement` ([conventions](conventions.md)): dependencies point down; a feature never imports
or depends on another feature; no third-party dependency beyond `purlay-swift`; OS-version checks only in `PurlayDesign`.

No `Feature*` package exists yet. The screen after sign-in is a placeholder ("Signed in"); everything the engine can do
(channels, messages, threads, attention, settings) is in `PurlayKit` and has no iOS screen. Adding a module is one package
under `Packages/Feature<Module>` plus one line where the `ModuleRegistry` is built; the registry is not yet instantiated in `App`.

## 3. How the app talks to the server

The engine in `PurlayKit` does this; the app supplies the platform pieces through `AppEnvironment`.

1. **Handshake.** `GET /api/client` (public) returns the server version, contract version and capabilities. A server the app
   cannot serve, or an app the server no longer serves (`426 CLIENT_TOO_OLD`), is a `ServerProblem`, a phase of its own.
2. **Sign-in, no password in the app.** `ASWebAuthenticationSession` opens the server's sign-in page. After the person approves,
   the page calls `POST /api/native/authorize` (PKCE challenge and state) and the server redirects to `purlay://auth?code&state`
   (the scheme is fixed by the server and set in `Config/Base.xcconfig`). The app calls `POST /api/native/token` with the code,
   the verifier and the device name, and receives the session as the `__Host-purlay_session` cookie, kept in the Keychain and
   sent on every request and on the WebSocket upgrade. Sessions are listed and revocable per device.
3. **Reads and writes** over HTTP with keyset pagination; every error is `{ error: { code, message } }`, matched from the
   generated union. `X-Purlay-Client: ios/<version> contract/<n>` names the platform; the server labels the session
   `Purlay for iOS/<version> (<device>)`.
4. **Realtime.** One WebSocket per signed-in session; on reconnect the client replays from its cursors. Sends paint first and
   reconcile after; a failed send shows as failed, with retry (the outbox).
5. **Server address.** The hosted address by default; Debug builds read `PURLAY_DEV_SERVER` and may use plain HTTP to a local
   server (ATS exception written into `Info.plist` in Debug only). Release keeps App Transport Security strict and
   talks to the hosted address only; letting a self-hoster enter their own is FR-025 and not built.

Not built, and needed before a release: closed-app delivery (APNs, §6), a local store for cold start, and the server's
minimum-client gate for `ios` (`MIN_CLIENT_*` names macOS only).

## 4. Design system and OS-version seam

All version branching lives in `PurlayDesign`, expressed as modifiers named by role. Today there is one,
`purlaySurface(.floatingControl | .panel, in:)`; features never write `#available`. Glass belongs on the navigation layer,
never on content. Colour, spacing and type come from `PurlayTokens`, so iOS and macOS cannot drift. Toolbar, tab bar,
haptics, motion and component modifiers are added to `PurlayDesign` as the first screens need them, not before.

## 5. Project and tooling

- XcodeGen: `project.yml` is the definition, `*.xcodeproj` is generated and ignored. One `xcconfig` per configuration, bundle
  prefix `dev.purlay`, bundle id `dev.purlay.ios`, languages English and Turkish.
- `.swift-format` is owned by `purlay-swift` and shared with `purlay-macos`; `scripts/check-shared-files` fails on any copy
  that differs from its owner.
- Tests: Swift Testing for logic; XCUITest for the sign-in against a real server (skipped without one).
- `make verify` (the lanes a pull request needs) and `make verify-security` are the entry points over `scripts/verify`
  ([ADR 0005](../decisions/0005-verify-entry-point-and-secret-scan.md)). CI runs the lanes side by side on `xcode-27` runners.

## 6. What is next (build order)

1. **Shell:** instantiate the registry, adaptive navigation (tab bar on iPhone, sidebar on iPad), workspace switcher.
2. **Chat vertical slice:** channel list, feed, composer, optimistic send, threads, on top of the existing engine.
3. **Inbox, search, profile and settings, Deep Work and quiet hours.**
4. **APNs:** needs a server endpoint and a sender in the push worker (the server speaks Web Push only, D-126), then the app side.
5. **Issues module**, then each new server module in the same pattern.
6. **Release:** distribution is not decided (see the [vision](../product/vision.md), Q-001); signing, a privacy manifest, an app
   icon and a TestFlight lane follow it ([tech debt](tech-debt.md)).

## 7. Repositories

```
purlay          server and THE contract (packages/types), publishes a versioned contract bundle
purlay-swift    Apple-only shared code: generated Contract, Kit, Tokens, the engine (macOS, iOS)
purlay-ios      this app and its Feature* packages
purlay-macos    the Mac app, on the same purlay-swift
```

The contract stays in `purlay`: a route and its type change in one commit, and CI there proves the bundle. A later Android
client would share the bundle, not Swift code (ADR 0004).

## 8. Open items

- Local store technology for cold start (SwiftData or SQLite): decide with a replay spike before the chat slice ships.
- Apple Developer team, and the hosted server address for Release (`ServerAddress.hosted`).
