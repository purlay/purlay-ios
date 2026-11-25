# 0001. iOS 18 floor, iOS 27 SDK, one availability seam

Status: accepted, 2026-11-25

**Context.** The app must run on iOS 18 through 27 and use Liquid Glass fully where the system has it.

**Decision.** Deployment target iOS 18.0, built with the iOS 27 SDK. Every OS-version branch lives in
`PurlayDesign` as a modifier named by role (`purlaySurface(.floatingControl)`); features never write
`#available`. From iOS 26 the system's glass; before, a system `Material` in the same shape. Glass is for the
navigation layer only.

**Rejected.** *iOS 26 floor:* leaves iOS 18–25 devices out. *Two hand-built designs:* doubles the work and the
test matrix. *Drawing glass by hand:* fights the system and its accessibility settings.

**Consequences.** One place to audit for version drift; snapshot tests run on iOS 18 and 27. iOS 27 APIs are
adopted behind the seam as they are needed.
