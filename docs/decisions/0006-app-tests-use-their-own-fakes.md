# 0006. The app's tests use fakes of their own, not `PurlayTestSupport`

Status: accepted, 2026-11-26

**Context.** `purlay-swift` ships fakes for the network, the Keychain and the browser as a product, `PurlayTestSupport`. The app's
unit tests (`PurlayTests`) are hosted by the app, which loads `PurlayKit` as a framework. Linking `PurlayTestSupport` into the test
bundle put 4,302 `PurlayKit` symbols into the bundle as well, as a static copy: the runtime logged `Class PurlayKit.Connection is
implemented in both …` for every class of the package. Two copies of one Swift class are two types, so a test could pass or fail on
a type that is not the one the app uses.

**Decision.** `Tests/PurlayTests/Fakes.swift` holds the few fakes the app's tests need (a scripted transport with an offline switch,
a scripted browser, an in-memory session store, owner memory and preferences). `PurlayTestSupport` is not linked into this target.
`PurlayKit` and `PurlayContract` are, so that the tests see the same dynamic frameworks as the app.

**Rejected.** *Keep `PurlayTestSupport` and ignore the warnings:* the duplicate types are the thing a test must not have.
*Test the screens inside `purlay-swift` or a package:* the screens and the composition root live in the app, and are what these
tests are for. *Make `PurlayTestSupport` a dynamic product:* that is `purlay-swift`'s decision and would change every consumer.

**Consequences.** About 100 lines of fakes are written twice (here and in `purlay-swift`). They implement public protocols, so a
change to a protocol fails to compile here at once. Revisit if `purlay-swift` makes its test support a dynamic product: then the
local copies can go.
