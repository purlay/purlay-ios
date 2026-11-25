# Architecture decision records

One file per decision, numbered, never rewritten: a changed decision is a new record that supersedes the old.

| # | Decision |
|---|---|
| [0001](0001-deployment-target-and-design-language.md) | iOS 18 floor, iOS 27 SDK, one availability seam for Liquid Glass |
| [0002](0002-shared-swift-packages.md) | Share Contract, Kit and Tokens with macOS; extract to `purlay-swift` later |
| [0003](0003-feature-modules.md) | One feature package per server module, registered, never importing each other |
| [0004](0004-contract-single-source.md) | The contract stays in the server repository; every platform generates from its bundle |
