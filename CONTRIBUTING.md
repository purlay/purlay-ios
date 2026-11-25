# Contributing to Purlay for iOS

The rules every Purlay repository shares (branches, commits, pull requests, the agreement) are in the organisation's
[CONTRIBUTING.md](https://github.com/purlay/.github/blob/main/CONTRIBUTING.md). This file is what is specific to this one.

## Before you push

```sh
scripts/verify
```

Four lanes, which CI runs side by side: `rules` (branch name, shared files, the decision rules and a demonstration that each refuses
its violation), `packages` (the packages' tests on macOS), `build` (format, and the app built for iOS) and `simulator` (the app's and
the packages' tests on a simulator). A pull request runs the first three, because starting a simulator costs minutes on a hosted
runner whatever is tested; `simulator` runs for a pull request that changes the app itself (`App/`, `Tests/PurlayTests/`,
`project.yml`, `Config/`), and always on `main`, on the weekly schedule and for a release. Compiled code is cached by content, so
the second run is much faster than the first. A pull request is checked in about two minutes; keep it that way: a change that makes
the check slower needs a reason in its description.

## What the rules protect

The decision records in [`docs/decisions`](docs/decisions) are held by `scripts/enforcement`, so they do not depend on review:

- one iOS floor and one `purlay-swift` version, wherever they are stated;
- OS-version checks (`#available`) only in `PurlayDesign`;
- a feature package never imports or depends on another feature;
- no dependency beyond `purlay-swift`;
- no unchecked concurrency escape and nothing that can trap on a value it was handed.

If a rule is in the way, change the decision first (a new record that supersedes the old), then the rule.

## Adding a server module's screens

One new package under `Packages/Feature<Module>` that conforms to `FeatureModule`, and one line in the app's `ModuleRegistry`
([ADR 0003](docs/decisions/0003-feature-modules.md)). Shared drawing goes in `PurlayDesign`; what two features both need goes in
`PurlayModuleAPI` first.

## Strings, accessibility, versions

Strings go in the string catalogue in English and Turkish. Every control has an accessibility label, text uses Dynamic Type, and
nothing is conveyed by colour alone. The app runs on iOS 18 and later and is built for the newest: use the new API behind
`PurlayDesign`'s modifiers, with the older path beside it.

## Shared files

`LICENSE`, `CLA.md`, `SECURITY.md` and `.editorconfig` belong to `purlay/purlay`; `.swift-format`, `NOTICE` and the shared scripts
belong to `purlay/purlay-swift`. Change them at their owner and copy; `scripts/check-shared-files` fails on any difference.
