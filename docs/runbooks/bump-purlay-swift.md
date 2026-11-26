# Move to a new `purlay-swift` release

When: `purlay-swift` has published a release this app needs (a new engine feature, a new contract version).

1. Read the release's notes in `purlay-swift` `CHANGELOG.md`, and whether it changes `Contract/contract.lock` (a new server version).
2. Change the one version, everywhere it is stated: `project.yml` (`packages: PurlaySwift: from:`) and the `from:` in every
   `Packages/*/Package.swift` that names `purlay-swift`. `scripts/enforcement` fails if they differ, which is the check that you
   found them all.
3. `scripts/verify` (all lanes, simulator included). A new contract version can change generated types the app uses.
4. If the release moves a shared file (`.swift-format`, `NOTICE`, a script), copy it from `purlay-swift` first:
   [change a shared file](change-a-shared-file.md).
5. Update the "Current status" line in `docs/README.md` if the version is named there, and `CHANGELOG.md` if the change is visible.
6. Do not edit an old decision record that quotes an earlier version: a record states what was true when it was written.
