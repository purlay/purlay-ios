# Purlay for iOS

The native iOS and iPadOS client for [Purlay](https://github.com/doancan/purlay): team chat today, and the
modules that follow it. Swift 6, SwiftUI, Liquid Glass on iOS 26 and later, a quiet system-material fallback
down to iOS 18.

> **Status: foundation.** The project, package graph, sign-in plumbing and CI are in place; screens are not.
> See [`docs/architecture/overview.md`](docs/architecture/overview.md) for the plan and build order.

## Requirements

- Xcode 27 or newer, [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Build

```sh
xcodegen generate
xcodebuild -project Purlay.xcodeproj -scheme Purlay -destination 'generic/platform=iOS Simulator' build
scripts/verify          # package tests, app build, app tests
```

Debug builds may point at another server: `PURLAY_DEV_SERVER=http://localhost:4390`.

## Documentation

| Folder | Holds |
|---|---|
| [`docs/architecture/`](docs/architecture) | Package graph, server integration, design-system seam, build order |
| [`docs/decisions/`](docs/decisions) | Architecture decision records: what was chosen, and what was rejected |
| [`docs/development/`](docs/development) | Setting up, building, testing |

## License

[AGPL-3.0](LICENSE). Contributions are under the [contributor licence agreement](CLA.md). Security reports:
[`SECURITY.md`](SECURITY.md).
