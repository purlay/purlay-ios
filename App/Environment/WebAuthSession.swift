import AuthenticationServices
import PurlayKit
import Synchronization
import UIKit

/// The system browser's own sign-in session: the page opens with the sign-ins the person already has, and the server's
/// redirect to `purlay://` comes back here. Not a web view: no form of the app's own, and nothing to phish.
@MainActor
final class WebAuthSession: NSObject, WebAuthenticator, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    nonisolated func authenticate(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let answer = Answer(continuation)
            Task { @MainActor in
                // The session answers on a queue of its own, so the handler must not be main-actor isolated.
                let session = ASWebAuthenticationSession(
                    url: url, callbackURLScheme: callbackScheme, completionHandler: Self.handler(answer))
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = false
                self.session = session
                if !session.start() {
                    answer.give(.failure(WebAuthenticatorError.failed("the browser could not be started")))
                }
            }
        }
    }

    private nonisolated static func handler(_ answer: Answer) -> @Sendable (URL?, (any Error)?) -> Void {
        { callback, error in
            if let callback {
                answer.give(.success(callback))
            } else if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                answer.give(.failure(WebAuthenticatorError.cancelled))
            } else {
                answer.give(.failure(WebAuthenticatorError.failed(error?.localizedDescription ?? "no answer")))
            }
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

/// The one answer a sign-in gives: a session that both fails to start and then reports the failure would resume twice.
private final class Answer: Sendable {
    private let continuation: Mutex<CheckedContinuation<URL, any Error>?>

    init(_ continuation: CheckedContinuation<URL, any Error>) {
        self.continuation = Mutex(continuation)
    }

    func give(_ result: Result<URL, any Error>) {
        let waiting = continuation.withLock { held in
            defer { held = nil }
            return held
        }
        waiting?.resume(with: result)
    }
}
