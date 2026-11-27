import Foundation
import PurlayContract
import PurlayKit

/// Every sentence a person reads on the app's own screens, as a value a catalogue translates (`Localizable.xcstrings`). The model
/// hands over what happened; this says it. The server's own `message` and a platform error's description are English written for
/// a log, and never reach a screen.
enum Words {
    static let connecting = LocalizedStringResource("Connecting…")
    static let waitingForBrowser = LocalizedStringResource("Waiting for the Browser…")
    static let loadingWorkspace = LocalizedStringResource("Loading your workspace…")
    static let signInPrompt = LocalizedStringResource("Continue in your browser to sign in securely.")
    static let signInButton = LocalizedStringResource("Sign In with Browser")
    static let tryAgain = LocalizedStringResource("Try Again")
    static let dismiss = LocalizedStringResource("Dismiss")
    static let workspace = LocalizedStringResource("Workspace")
    static let chat = LocalizedStringResource("Chat")
    static let openChatInBrowser = LocalizedStringResource("Open Chat in Browser")
    static let noWorkspaceModules = LocalizedStringResource("No Modules Available")
    static let noWorkspaces = LocalizedStringResource("No Workspaces Yet")
    static let twoFactorRequired = LocalizedStringResource("Two-Factor Authentication Required")
    static let setUpTwoFactor = LocalizedStringResource("Set Up Two-Factor Authentication")
    static func switchWorkspace(_ current: String) -> LocalizedStringResource {
        LocalizedStringResource("Switch Workspace, \(current)")
    }

    static func backToWorkspace(_ name: String) -> LocalizedStringResource {
        LocalizedStringResource("Back to \(name)")
    }

    /// For a refusal that has no sentence of its own on these screens: said plainly, never as a description of the error.
    static let generic = LocalizedStringResource("Something went wrong. Try again.")

    /// The fixed sentences of the screens, so a test can look at each in every language.
    static let fixed: [LocalizedStringResource] = [
        connecting, waitingForBrowser, loadingWorkspace, signInPrompt, signInButton, tryAgain, dismiss, generic,
        workspace, chat, openChatInBrowser, noWorkspaceModules, noWorkspaces, twoFactorRequired,
        setUpTwoFactor,
    ]

    /// What stands between the app and the server: the title, and what the person can do about it.
    static func problem(_ problem: ServerProblem) -> (title: LocalizedStringResource, detail: LocalizedStringResource) {
        switch problem {
        case .unreachable:
            return (
                LocalizedStringResource("Server Unavailable"),
                LocalizedStringResource("Check your connection, then try again.")
            )
        case .notAPurlayServer:
            return (
                LocalizedStringResource("That doesn't look like a Purlay server"),
                LocalizedStringResource("The address answered, but not as Purlay does.")
            )
        case .rateLimited:
            return (
                LocalizedStringResource("Too many requests"),
                LocalizedStringResource("The server asks you to wait a moment.")
            )
        case .appTooOld(let minimum):
            let detail =
                minimum.appVersion.map { LocalizedStringResource("It needs version \($0) or newer.") }
                ?? LocalizedStringResource("Update Purlay, then try again.")
            return (LocalizedStringResource("This server needs a newer Purlay"), detail)
        case .serverTooOld:
            return (
                LocalizedStringResource("This server is older than this app supports"),
                LocalizedStringResource("Ask whoever runs it to update the server.")
            )
        case .unusableOrigin:
            // The address the server gave is the server's text, not ours to show.
            return (
                LocalizedStringResource("The server gave an address this app can't use"),
                LocalizedStringResource("Ask whoever runs the server to check its address settings.")
            )
        }
    }

    /// Why a sign-in did not complete. `nil` for the person closing the page: that is a choice, and nothing is said of it.
    static func signIn(_ error: SignInError) -> LocalizedStringResource? {
        switch error {
        case .cancelled: return nil
        case .browserFailed: return LocalizedStringResource("The browser could not be opened.")
        case .callbackRejected:
            return LocalizedStringResource("The sign-in did not come back the way it should. Try again.")
        case .codeRejected: return LocalizedStringResource("That sign-in expired or was already used. Try again.")
        case .rateLimited: return LocalizedStringResource("Too many attempts. Wait a moment and try again.")
        case .refused: return LocalizedStringResource("The server did not accept this sign-in.")
        case .noSessionInAnswer: return LocalizedStringResource("The server did not start a session. Try again.")
        case .unreachable: return LocalizedStringResource("The server could not be reached.")
        case .storage: return LocalizedStringResource("The session could not be saved to your Keychain.")
        }
    }

    /// What the model says that is not a screen of its own. `nil` says nothing. A kind these screens have no sentence for is said
    /// generically: the model never hands over English, so nothing leaks, and the sentence for a new kind is added with its screen.
    static func notice(_ kind: Notice.Kind) -> LocalizedStringResource? {
        switch kind {
        case .invalidAddress(let problem): return address(problem)
        case .signInFailed(let error): return signIn(error)
        case .sessionExpired: return LocalizedStringResource("Your session has expired. Sign in again.")
        case .sessionEndedByServer:
            return LocalizedStringResource("You were signed out by the server. Sign in again.")
        case .signedOutElsewhere: return LocalizedStringResource("You were signed out.")
        case .sessionEndsSoon(let end):
            let when = end.formatted(date: .abbreviated, time: .shortened)
            return LocalizedStringResource("Your session ends on \(when). Sign in again before then to stay connected.")
        case .storageProblem:
            return LocalizedStringResource(
                "Unsent messages can't be saved on this device right now. Sending still works.")
        case .originMismatch:
            return LocalizedStringResource("The server refused this app's connection. Check the server's address.")
        default: return generic
        }
    }

    private static func address(_ problem: ServerAddress.Problem) -> LocalizedStringResource {
        switch problem {
        case .empty: return LocalizedStringResource("Type the address of your Purlay server.")
        case .unreadable: return LocalizedStringResource("That is not an address a browser would open.")
        case .notAWebAddress: return LocalizedStringResource("Use a web address, starting with https.")
        case .hasCredentials: return LocalizedStringResource("Leave the user name and password out of the address.")
        case .hasMoreThanAHost: return LocalizedStringResource("Give only the server's address, without a path.")
        case .insecure: return LocalizedStringResource("This server must be reached over https.")
        }
    }
}
