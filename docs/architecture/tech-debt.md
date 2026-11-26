# Technical debt

Accepted debts only. A repaid line is deleted (history is in git). "Below the floor" is a debt taken on at the owner's
insistence under the quality floor; none exists.

| ID | Debt | Impact | Repayment condition | Owner | Below the floor? |
|---|---|---|---|---|---|
| TD-003 | `AppIcon` set has no image (its `Contents.json` names a 1024 pt slot and no file) | Medium for release: submission is refused; the app shows a blank icon | Before the first TestFlight build. **Owner action:** supply the artwork, a 1024 × 1024 px PNG without transparency, and drop it into `App/Resources/Assets.xcassets/AppIcon.appiconset` under the filename `Contents.json` names | App owner | No |
| TD-005 | No release path in CI: no signing identity (`DEVELOPMENT_TEAM` is empty), no archive, no TestFlight upload | High for release; none for development | When distribution is decided (Q-001); then an ADR and a runbook. **Owner action:** settle Q-001, enrol the Apple Developer team and give its id (for `DEVELOPMENT_TEAM`), and provide the signing assets: an App Store Connect API key kept as a CI secret | App owner | No |
| TD-007 | The sign-in's approval step is not driven by a UI test (the system browser's page cannot be automated in the simulator); the server's half is tested in `purlay-swift` | Low: a regression in the app's half of the redirect would be found by hand | If Apple exposes a way to drive the sheet, or when a device-lab lane exists | App owner | No |
| TD-009 | A stored session the Keychain cannot read is said as "Unsent messages can't be saved on this device right now": `purlay-swift` reports a failed restore with the notice it uses for the outbox's storage, so the sentence is for the wrong failure. Seen in the simulator with an unsigned build | Low: the person is told something unrelated, and signs in again | `purlay-swift` gives the restore failure a notice kind of its own; then add its sentence to `Words` and the catalogue | App owner | No |
