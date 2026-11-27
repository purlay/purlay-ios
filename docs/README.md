# Purlay for iOS

The native iPhone and iPad client for [Purlay](https://github.com/purlay/purlay): team chat today and the modules that follow it.
Swift 6, SwiftUI, Liquid Glass from iOS 26 and a system material before; iOS 18 is the floor. It uses the shared engine in
[`purlay-swift`](https://github.com/purlay/purlay-swift) and talks to a Purlay server (hosted or self-hosted).

## Current status

- **Stage:** foundation. The project, package graph, native sign-in and CI are in place and tested against a real server. Nothing is released.
- **Works:** launch and handshake, sign-in through the system browser (PKCE), resuming a stored session, a screen per phase of
  the shared `AppModel` (connecting, loading, sign-in, and a problem screen per kind of server problem with Try Again), every
  sentence in English and Turkish, dismissible notices, a privacy manifest, the glass surface seam and the app icon.
  The signed-in shell switches workspaces and uses system tabs on iPhone and a sidebar in regular width. Chat has a joined-channel
  list, a paginated feed and text sending with a retry for failed messages. The Account menu signs out on this device or everywhere.
- **Not yet:** threads, APNs and a release path.
- **Known problems:** see [tech debt](architecture/tech-debt.md); the one that blocks a release is TD-005 (signing and the release path).
- **Seen in the simulator, 2026-11-26** (a build signed ad hoc, a server that answers only the handshake): connecting; loading;
  the problem screen in English (light) and in Turkish (dark, at the largest accessibility text size, where it scrolls and the
  button wraps); sign-in in English and Turkish; the notice banner in English and Turkish.
- **Shell seen in the simulator, 2026-11-27:** iPhone on iOS 18.5 and iPad on iOS 27.0, against a local fixture.
  The UI test switched from a Chat workspace to a workspace without Chat and back. VoiceOver itself was not exercised.
- **Baseline, measured 2026-11-26** with `scripts/verify` (all lanes, warm cache, 20 s): rules, format, the packages' tests on
  macOS, the app built for iOS, and the tests on a simulator (28 of the app's own) all pass; the secret scan found no leak in the history.
  The sign-in UI tests skip themselves without a server, so they were not run.

## Current constraints

- One iOS floor (18), one `purlay-swift` version, no other dependency, no `#available` outside `PurlayDesign`, no feature importing a
  feature, no concurrency escape: held by `scripts/enforcement` — [ADR 0001](decisions/0001-deployment-target-and-design-language.md),
  [0002](decisions/0002-shared-swift-packages.md), [0003](decisions/0003-feature-modules.md).
- The contract is generated from the server's bundle and never edited here — [ADR 0004](decisions/0004-contract-single-source.md).
- No build is published until the owner settles the licensing basis for distribution (Q-001 in [requirements](product/requirements.md)).
- Shared files belong to their owners and are copied, never edited here — [runbook](runbooks/change-a-shared-file.md).

## Next slices

1. Threads, inbox and search.

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
The repositories are public, so `scripts/check-shared-files` needs no token, but an anonymous address may make 60 GitHub requests an hour and one run makes ten: `GITHUB_TOKEN="$(gh auth token)"` lifts the limit.

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

- [0006 — The app's tests use fakes of their own](decisions/0006-app-tests-use-their-own-fakes.md)
- [0005 — `make verify` over the lanes of `scripts/verify`, and a secret scan](decisions/0005-verify-entry-point-and-secret-scan.md)
- [0004 — The contract stays in the server repository](decisions/0004-contract-single-source.md)
- [0003 — One feature package per server module](decisions/0003-feature-modules.md)
- [0002 — Share Contract, Kit and Tokens through `purlay-swift`](decisions/0002-shared-swift-packages.md)
- [0001 — iOS 18 floor, iOS 27 SDK, one availability seam](decisions/0001-deployment-target-and-design-language.md)

## Working rule

Every change: read the relevant document, implement, update the documents in the same change, record a decision if one was made,
run `make verify`.
