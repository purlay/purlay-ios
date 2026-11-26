# Product vision: Purlay for iOS

> Last updated: 2026-11-26 · Owner: the Purlay owner · Server's product document: `purlay` `docs/PRD.md`

## Problem

People who run their work in Purlay (team chat today, issues and more modules to follow) are away from a desk for much of the
day. The installable web application works on a phone, but it cannot receive closed-app notifications, cannot use the system's
own navigation and materials, and does not feel like part of the phone.

## Target users

- **Primary:** a member of a Purlay workspace, on an iPhone, reading and answering messages away from a desk.
- **Secondary:** the same person on an iPad, with a larger layout; and a person on a self-hosted Purlay, who needs to point the
  app at their own server.

## Job to be done

When a conversation in my workspace needs me and I am away from my desk, I want to read it and answer it from my phone, so that
my team is not waiting on me.

## Value proposition

- Native: the system's own navigation, toolbars, sheets and Liquid Glass, not a web page in a frame.
- No password in the app: sign-in goes through the system browser to the server's own page.
- As modular as the server: a module the workspace does not run is not shown, and one the app does not know is ignored.
- Open: the app is AGPL-3.0 like the server. A self-hoster will point it at their own server (FR-025); today only a Debug build can.

## Platforms

iPhone and iPad, iOS 18 and later, built with the iOS 27 SDK. Liquid Glass from iOS 26, a system material before.

## Success metrics

| Metric | Target | Measured by | Date |
|---|---|---|---|
| Cold load to an interactive channel, warm cache | < 1.5 s | the server's performance budget, measured on a device once chat ships | first TestFlight with chat |
| Keystroke to own message painted | < 16 ms, never awaiting the network | the same budget | first TestFlight with chat |
| Accessibility audit of every shipped screen | zero failures | `performAccessibilityAudit` in the UI tests | each screen, as it ships |

Adoption figures (weekly active people) are not set: see Q-002.

## First slice (MVP)

- **Walking skeleton (done):** launch, handshake, sign in through the system browser, resume a stored session, reach the signed-in screen.
- **MVP:** FR-020 to FR-024 in [requirements](requirements.md): the shell, then the chat slice (channels, feed, send, sign out).

## Non-goals

- No password form and no web view of the app's own for sign-in.
- No client-side encryption of messages (it would make server-side search impossible; the server's stated privacy answer is self-hosting).
- No dynamic plug-ins for modules: a module is a package compiled into the app, as the server's modules are.
- No Mac Catalyst or watchOS in this repository; the Mac has its own app, `purlay-macos`.
- No Kotlin Multiplatform or shared runtime with a future Android client; it shares the contract bundle only.

## Constraints

- **Distribution is undecided.** The App Store's terms and the AGPL do not sit together, and iOS has no other channel for an
  ordinary person. The owner must settle the licensing basis before a build is released; until then the app is built and tested,
  not published (server decision D-338). See Q-001.
- Personal data: the app holds only a session cookie (Keychain), preferences and drafts. No analytics or tracking SDK; no
  dependency beyond `purlay-swift`.
- Hosting: the app talks to a Purlay server, hosted or self-hosted, over HTTPS (plain HTTP to a local server in Debug only).
