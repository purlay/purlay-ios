# 0005. `make verify` over the lanes of `scripts/verify`, and a secret scan

Status: accepted, 2026-11-26 (recorded retroactively for the lanes, which existed from the foundation; new for the secret scan)

**Context.** The repository's checks were already `scripts/verify`, in lanes (`rules`, `packages`, `build`, `simulator`) that CI runs
side by side. There was no entry point a person or a pipeline could rely on by name, and nothing looked for a secret committed
to the history. Swift Package Manager has no standard vulnerability scanner (there is no advisory database the way `npm audit` has
one), so the dependency risk is held another way.

**Decision.**
1. `scripts/verify` keeps the lanes; a `Makefile` is the stable entry point and holds no logic: `make setup` installs the pinned tools,
   `make verify` runs the lanes a pull request needs (`rules`, `packages`, `build`), `make verify-security` runs the secret scan,
   `make verify-all` runs every lane including the simulator.
2. A `security` lane runs gitleaks over the whole history (`gitleaks git`). The version and the digests of its release assets are pinned in
   `scripts/install-gitleaks`, the same way XcodeGen is pinned, and the script is shared by the three Swift repositories, with
   `purlay-swift` as owner. CI runs it as its own job with a full clone, and the final check requires it to succeed: it cannot be skipped,
   even for a pull request that changes only documents.
3. Dependency risk is held by having one dependency, `purlay-swift`, which is ours, at one released version that `scripts/enforcement` keeps
   identical everywhere (ADR 0002), and by Dependabot for the GitHub Actions the workflows use. A new third-party dependency needs its
   own record and is refused by `scripts/enforcement` until it has one.

**Rejected.** *A `just` file or Makefile that holds the lanes:* duplicates what the scripts do and what CI calls. *Scanning only the
working tree:* a secret committed and then removed is still in the history. *Installing gitleaks with Homebrew:* slow on a hosted runner and not
pinned (the reason XcodeGen is downloaded, not brewed). *A third-party SPM audit tool:* none is established; adding one would be a dependency
of its own.

**Consequences.** (+) One name for each set of checks; a leaked secret fails the pull request that carries it. (−) The history scan sees only
what gitleaks's rules recognise. (−) Until a Swift vulnerability database exists, a vulnerability in `purlay-swift` is found by us, not by a tool.
