# Change a file that several repositories share

Some files are one file kept in several repositories. `scripts/check-shared-files` compares each copy with its owner's and fails
on any difference, so a change is made once, at the owner, and copied.

| Owner | Files |
|---|---|
| `purlay/purlay` | `LICENSE`, `CLA.md`, `SECURITY.md`, `.editorconfig` |
| `purlay/purlay-swift` | `.swift-format`, `NOTICE`, `scripts/check-shared-files`, `scripts/check-branch`, `scripts/install-xcodegen`, `scripts/install-gitleaks` |

1. Make and merge the change in the owner's repository. The check reads the owner's `main`, so nothing is compared until it is merged.
2. Copy the file byte for byte into `purlay-ios` (and `purlay-macos`, which has the same list). Run `GITHUB_TOKEN="$(gh auth token)" scripts/check-shared-files`;
   the repositories are public, but an anonymous address is limited to 60 requests an hour and a run makes ten, so a local run past the limit is refused (CI passes its own token).
3. A new shared file is added to the list in `scripts/check-shared-files` itself, which is shared: change that script at
   `purlay-swift` first, then copy it everywhere.
4. Order of merging when several repositories change together: the owner first, then the others, or their `rules` lane is red in between.
5. Bumping a tool pin (XcodeGen, gitleaks) is the same: change the version and digest in the owner's script, check the digest
   against the one GitHub shows for the release asset and against the file you downloaded, merge, then copy.
