# 0003. One feature package per server module

Status: accepted, 2026-11-25

**Context.** Purlay is a core plus modules (chat, issues; tasks, time and GitHub management to come). The app
must grow the same way without the later modules reshaping the earlier ones.

**Decision.** Each server module has a `Feature*` Swift package that conforms to `FeatureModule` and is listed in
the app's `ModuleRegistry`. The registry draws a feature only where the workspace's membership allows its module
and ignores ids it does not know. Features depend on `PurlayModuleAPI`, `PurlayDesign` and the shared core,
never on one another.

**Rejected.** *One app target with folders:* nothing stops cross-feature imports. *Dynamic plug-ins:* the server
has none either (permanent non-goal).

**Consequences.** Adding a module is one package and one registry line. Cross-module behaviour (deep links,
inbox notices, search results) is declared in `PurlayModuleAPI` first.
