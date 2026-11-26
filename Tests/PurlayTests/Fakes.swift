import Foundation
import PurlayKit
import Synchronization

// The outside of the app, replaced for a test: the network, the Keychain, the browser and the data owner's memory. They are written
// here and not taken from `PurlayTestSupport`: linking that product into this test bundle puts a second, static copy of `PurlayKit`
// beside the one the app loads, and two copies of one class are two types.

/// Answers a request as a script says, and remembers what it was asked. A request nobody scripted is a failure the test sees, not a hang.
actor ScriptedTransport: HTTPTransport {
    enum Step: Sendable {
        case respond(HTTPResponse)
        case fail(TransportError)
    }

    private var script: [Step]
    private var offline = false
    private(set) var requests: [HTTPRequest] = []

    init(_ steps: [Step] = []) {
        script = steps
    }

    /// While offline every request fails, however often the client tries again; the script is kept for when the network is back.
    func setOffline(_ offline: Bool) { self.offline = offline }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        requests.append(request)
        if offline { throw TransportError.offline }
        guard !script.isEmpty else {
            throw TransportError.connection("nothing was scripted for \(request.method) \(request.url.path)")
        }
        switch script.removeFirst() {
        case .respond(let response): return response
        case .fail(let error): throw error
        }
    }

    nonisolated static func json(_ status: Int, _ text: String) -> Step {
        .respond(HTTPResponse(status: status, headers: ["Content-Type": "application/json"], body: Data(text.utf8)))
    }
}

/// Answers the sign-in page as a script says: with the person closing it, or with the browser failing.
actor ScriptedAuthenticator: WebAuthenticator {
    private var answers: [WebAuthenticatorError]
    private(set) var pages: [URL] = []

    init(_ answers: [WebAuthenticatorError] = []) {
        self.answers = answers
    }

    func authenticate(url: URL, callbackScheme: String) async throws -> URL {
        pages.append(url)
        guard !answers.isEmpty else { throw WebAuthenticatorError.failed("nothing was scripted") }
        throw answers.removeFirst()
    }
}

/// Keeps sessions in memory, and can refuse to forget one, as a keychain that will not does.
final class InMemorySessionStore: SessionStore {
    private struct State {
        var sessions: [String: StoredSession] = [:]
        var saves = 0
        var deleteFails = false
    }

    private let state = Mutex(State())

    func failDeletes() { state.withLock { $0.deleteFails = true } }
    var saves: Int { state.withLock { $0.saves } }

    func load(for server: ServerAddress) throws -> StoredSession? { state.withLock { $0.sessions[server.description] } }

    func save(_ session: StoredSession, for server: ServerAddress) throws {
        state.withLock {
            $0.sessions[server.description] = session
            $0.saves += 1
        }
    }

    func delete(for server: ServerAddress) throws {
        try state.withLock {
            if $0.deleteFails { throw KeychainError(status: -25291, operation: "delete") }
            $0.sessions[server.description] = nil
        }
    }
}

final class InMemoryOwnerMemory: OwnerMemory {
    private let state = Mutex<String?>(nil)
    func load() -> String? { state.withLock { $0 } }
    func save(_ owner: String?) { state.withLock { $0 = owner } }
}

/// Small preferences kept in memory, for the environment's one preference store.
final class MemoryPreferences: PreferenceStore {
    private let state = Mutex<[String: String]>([:])
    func string(for key: String) -> String? { state.withLock { $0[key] } }
    func set(_ value: String?, for key: String) { state.withLock { $0[key] = value } }
}
