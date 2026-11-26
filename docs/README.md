# Purlay for iOS

The native iPhone and iPad client for [Purlay](https://github.com/purlay/purlay): team chat today and the modules that follow it.
Swift 6, SwiftUI, Liquid Glass from iOS 26 and a system material before; iOS 18 is the floor. It uses the shared engine in
[`purlay-swift`](https://github.com/purlay/purlay-swift) and talks to a Purlay server (hosted or self-hosted).

## Current status

- **Stage:** foundation. The project, package graph, native sign-in and CI are in place and tested against a real server. Nothing is released.
- **Works:** launch and handshake, sign-in through the system browser (PKCE), resuming a stored session, a screen per phase of
  the shared `AppModel`, the module registry (as a package, not yet used by the app), the glass surface seam, the app icon (the Purlay mark,
  drawn from `Design/purlay.svg` by `scripts/icon`).
- **Not yet:** any screen after sign-in (it shows "Signed in"), a feature package, APNs, a release path. Next slice is in the list below.
- **Known problems:** see [tech debt](architecture/tech-debt.md); the ones that block a release are TD-002 and TD-005.
- **Baseline, measured 2026-11-26** with `scripts/verify` (all lanes, warm cache, 25 s): rules, format, the packages' tests on
  macOS, the app built for iOS, and the tests on a simulator all pass; the secret scan found no leak in the history. The sign-in UI
  tests skip themselves without a server, so they were not run.

## Current constraints

- One iOS floor (18), one `purlay-swift` version, no other dependency, no `#available` outside `PurlayDesign`, no feature importing a
  feature, no concurrency escape: held by `scripts/enforcement` — [ADR 0001](decisions/0001-deployment-target-and-design-language.md),
  [0002](decisions/0002-shared-swift-packages.md), [0003](decisions/0003-feature-modules.md).
- The contract is generated from the server's bundle and never edited here — [ADR 0004](decisions/0004-contract-single-source.md).
- No build is published until the owner settles the licensing basis for distribution (Q-001 in [requirements](product/requirements.md)).
- Shared files belong to their owners and are copied, never edited here — [runbook](runbooks/change-a-shared-file.md).

## Next slices

1. FR-020: the shell. Instantiate the registry, adaptive navigation, workspace switcher; close TD-001 and TD-004 with it.
2. FR-021, FR-022: the chat slice on the existing engine, after the local-store spike (A-003).
3. FR-023: sign out, on this device and everywhere.

## Quick start

**Requires:** Xcode 27 or later; the pinned XcodeGen and gitleaks come from `make setup`.

```sh
make setup                                  # install the pinned tools
xcodegen generate                           # write Purlay.xcodeproj from project.yml
xcodebuild -project Purlay.xcodeproj -scheme Purlay -destination 'generic/platform=iOS Simulator' build
scripts/verify simulator                    # the tests on a simulator
```

**Environment (Debug builds only):** `PURLAY_DEV_SERVER` (a server address, plain HTTP allowed for a local one),
`PURLAY_DEV_SESSION` (a stored session's cookie value), `PURLAY_DEV_RESET=1` (forget the stored session first).
`GITHUB_TOKEN="$(gh auth token)"` is needed locally for `scripts/check-shared-files`, because the repositories are private.

## Verification

```sh
make verify          # what a pull request needs: rules, format and package tests, the app built for iOS
make verify-security # the history scanned for secrets
make verify-all      # every lane, the simulator included (what main runs)
```

A change is not done until `make verify` is green, and `make verify-security` when it touches anything that could hold a secret.

## Project structure

```
App/                   composition root, real environment, one screen per phase
Design/                the logo (purlay.svg), the source of the app icon
Packages/              PurlayModuleAPI (feature protocol, registry), PurlayDesign (the OS-version seam)
Tests/                 PurlayTests (unit), PurlayUITests (sign-in against a real server)
Config/                xcconfig per configuration; project.yml defines the project
scripts/               verify (the lanes), enforcement (the decision rules), install-* (pinned tools), check-*
docs/                  this documentation
```

## Docs map

| Document | Read it when |
|---|---|
| [architecture/overview.md](architecture/overview.md) | Adding a package or module, or touching how the app talks to the server |
| [architecture/conventions.md](architecture/conventions.md) | Before any code change |
| [architecture/tech-debt.md](architecture/tech-debt.md) | Before a release; when a shortcut tempts you |
| [decisions/](decisions/) | Asking why something is the way it is; before changing the architecture |
| [product/vision.md](product/vision.md), [requirements.md](product/requirements.md) | Before changing what the app does |
| [development/getting-started.md](development/getting-started.md) | Setting up, local servers, the sign-in UI tests |
| [runbooks/](runbooks) | Moving to a new `purlay-swift`; changing a shared file |

## Latest decisions

- [0005 — `make verify` over the lanes of `scripts/verify`, and a secret scan](decisions/0005-verify-entry-point-and-secret-scan.md)
- [0004 — The contract stays in the server repository](decisions/0004-contract-single-source.md)
- [0003 — One feature package per server module](decisions/0003-feature-modules.md)
- [0002 — Share Contract, Kit and Tokens through `purlay-swift`](decisions/0002-shared-swift-packages.md)
- [0001 — iOS 18 floor, iOS 27 SDK, one availability seam](decisions/0001-deployment-target-and-design-language.md)

## Working rule

Every change: read the relevant document, implement, update the documents in the same change, record a decision if one was made,
run `make verify`.
