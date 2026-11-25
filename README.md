<div align="center">
  <h1>Purlay for iOS</h1>
  <p>Your team’s conversations, in your pocket.</p>
  <p>The native iPhone and iPad client for <a href="https://github.com/purlay/purlay">Purlay</a>, team chat today and the modules that follow it. Swift 6, SwiftUI, and Liquid Glass.</p>
  <p>
    <img src="https://img.shields.io/badge/iOS-18%2B-24292f?style=flat-square" alt="iOS 18 or later">
    <img src="https://img.shields.io/badge/built_for-iOS_27-24292f?style=flat-square" alt="Built with the iOS 27 SDK">
    <img src="https://img.shields.io/badge/Swift-6-f05138?style=flat-square" alt="Swift 6">
    <a href="https://github.com/purlay/purlay-ios/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/purlay/purlay-ios/ci.yml?branch=main&style=flat-square&label=CI" alt="CI status"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-24292f?style=flat-square" alt="AGPL-3.0 license"></a>
  </p>
</div>

> **Status: foundation.** The project, package graph, native sign-in and CI are in place and tested against a real
> server. The screens are next, beginning with a vertical slice of chat. Nothing is released yet.

## What it is

- **Native.** SwiftUI on iPhone and iPad, using the system's own navigation, toolbars, sheets and materials rather than
  drawing its own.
- **Current and compatible.** Built with the iOS 27 SDK and drawn in Liquid Glass from iOS 26. It runs down to iOS 18 with a
  system material in the same shape. Every OS-version decision sits in one package, so a screen never branches on a version.
- **As modular as the server.** Purlay is a core plus modules (chat, issues, and more to come). The app has one feature
  package per server module, shown only where the server runs it and the workspace may use it, and a module the app does not
  know is ignored.
- **No password in the app.** Sign-in goes through the system browser to the server's own page and returns by a one-time
  code bound to a secret the app keeps (PKCE). The session lives in the Keychain.

## Build

You need Xcode 27 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
xcodegen generate
xcodebuild -project Purlay.xcodeproj -scheme Purlay -destination 'generic/platform=iOS Simulator' build
scripts/verify    # shared files, decision rules, format, package tests, app tests
```

Debug builds can point at another server with `PURLAY_DEV_SERVER`. The development guide also shows how to run the sign-in
UI tests against a local server.

## Part of Purlay

The wire contract, design tokens and client engine come from [`purlay-swift`](https://github.com/purlay/purlay-swift),
shared with [`purlay-macos`](https://github.com/purlay/purlay-macos); the server and the contract's source of truth is
[`purlay`](https://github.com/purlay/purlay), whose README maps all the repositories.

## Documentation

| Folder | Holds |
|---|---|
| [`docs/architecture/`](docs/architecture) | Package graph, server integration, the design-system seam, build order |
| [`docs/decisions/`](docs/decisions) | Architecture decision records: what was chosen, and what was rejected |
| [`docs/development/`](docs/development) | Setting up, building, testing |

## License

[AGPL-3.0](LICENSE). Contributions are under the [contributor licence agreement](CLA.md). Security reports:
[`SECURITY.md`](SECURITY.md). Third-party notices: [`NOTICE`](NOTICE).
