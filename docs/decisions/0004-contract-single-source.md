# 0004. The contract stays in the server repository

Status: accepted, 2026-11-25

**Context.** An Android client is planned. A shared "API repository" was considered.

**Decision.** `packages/types` in `purlay` remains the only definition; `bun run contract:bundle` publishes a
versioned bundle. Each platform generates its own types and tokens from the pinned bundle and runs the
live-server contract test. Apple platforms share Swift code through `purlay-swift`; Android keeps its own
Kotlin core.

**Rejected.** *A separate contract repository:* a route and its type could no longer change in one commit, and
it would own nothing the bundle does not already carry. *Shared runtime (KMP):* see ADR 0002.

**Revisit** if third parties need published SDKs.
