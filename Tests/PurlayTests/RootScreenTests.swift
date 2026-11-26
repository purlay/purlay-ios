import PurlayContract
import PurlayKit
import Testing

@testable import Purlay

@MainActor
@Suite("the screen of each phase")
struct RootScreenTests {
    @Test("each phase of the model has exactly one screen")
    func everyPhase() {
        #expect(RootScreen(.launching) == .busy(.connecting))
        #expect(RootScreen(.checking) == .busy(.connecting))
        #expect(RootScreen(.signingIn) == .busy(.signingIn))
        #expect(RootScreen(.loading) == .busy(.loading))
        #expect(RootScreen(.signedOut) == .signIn)
        #expect(RootScreen(.ready) == .ready)
        #expect(RootScreen(.problem(.unreachable)) == .problem(.unreachable))
    }

    @Test("a server with no session kept asks the person to sign in")
    func signedOut() async {
        let harness = Harness([Harness.clientInfo()])
        await harness.model.connect()
        #expect(RootScreen(harness.model.phase) == .signIn)
        #expect(harness.model.notices.isEmpty)
    }

    @Test(
        "each thing that can stand between the app and the server is its own problem screen, said in words for a person",
        arguments: [
            (ScriptedTransport.Step.fail(.offline), ServerProblem.unreachable),
            (ScriptedTransport.json(404, "{}"), .notAPurlayServer),
            (ScriptedTransport.json(429, "{}"), .rateLimited(retryAfter: nil)),
            (
                Harness.clientInfo(minApp: "9.0.0"),
                .appTooOld(ClientMinimum(appVersion: "9.0.0", contractVersion: 1, downloadUrl: nil))
            ),
            (Harness.clientInfo(contract: 0), .serverTooOld(contract: 0)),
            (Harness.clientInfo(appURL: "ftp://x.test"), .unusableOrigin("ftp://x.test")),
        ])
    func problems(step: ScriptedTransport.Step, expected: ServerProblem) async {
        let harness = Harness([step])
        await harness.model.connect()
        #expect(harness.model.phase == .problem(expected))
        #expect(RootScreen(harness.model.phase) == .problem(expected))
        for language in ["en", "tr"] {
            let words = Words.problem(expected)
            let title = text(words.title, in: language)
            let detail = text(words.detail, in: language)
            #expect(!title.isEmpty && !detail.isEmpty)
            // A developer's description of the case is not a sentence for a person.
            for sentence in [title, detail] {
                #expect(!sentence.contains("ServerProblem") && !sentence.contains("unusableOrigin("))
                #expect(!sentence.contains("ftp://x.test"), "the server's own text is not shown")
            }
        }
    }

    @Test("trying again asks the server again, and a second tap before the answer asks nothing more")
    func retry() async {
        let harness = Harness([Harness.clientInfo()])
        await harness.transport.setOffline(true)
        await harness.model.connect()
        #expect(harness.model.phase == .problem(.unreachable))
        let asked = await harness.transport.requests.count
        await harness.transport.setOffline(false)
        async let first: Void = RootActions.retry(harness.model)
        async let second: Void = RootActions.retry(harness.model)
        _ = await (first, second)
        #expect(harness.model.phase == .signedOut)
        #expect(await harness.transport.requests.count == asked + 1, "one handshake, not two")
        await RootActions.retry(harness.model)
        #expect(await harness.transport.requests.count == asked + 1, "with no problem showing, retry asks nothing")
    }

    @Test("two quick taps on sign in open the browser once")
    func signInOnce() async {
        let harness = Harness([Harness.clientInfo()], browser: [.cancelled])
        await harness.model.connect()
        async let first: Void = RootActions.signIn(harness.model)
        async let second: Void = RootActions.signIn(harness.model)
        _ = await (first, second)
        #expect(await harness.authenticator.pages.count == 1)
        #expect(harness.model.phase == .signedOut)
        #expect(harness.model.notices.isEmpty, "closing the page is a choice, and nothing is said of it")
    }

    @Test("a browser that cannot be shown is said in a sentence, never as the platform's description")
    func browserFailure() async throws {
        let harness = Harness([Harness.clientInfo()], browser: [.failed("ASWebAuthenticationSessionError 2")])
        await harness.model.connect()
        await RootActions.signIn(harness.model)
        let notice = try #require(harness.model.notices.first)
        #expect(notice.kind == .signInFailed(.browserFailed("ASWebAuthenticationSessionError 2")))
        let words = try #require(Words.notice(notice.kind))
        #expect(text(words, in: "en") == "The browser could not be opened.")
        #expect(!text(words, in: "tr").contains("ASWebAuthenticationSessionError"))
        harness.model.dismiss(notice)
        #expect(harness.model.notices.isEmpty)
    }

    @Test(
        "an address the app cannot use is a problem screen with a sentence for it, and nothing is asked of the network")
    func unusableAddress() async throws {
        let harness = Harness([], serverAddress: "https://user:pw@x.test")
        await harness.model.launch()
        #expect(harness.model.phase == .problem(.unreachable))
        let notice = try #require(harness.model.notices.first)
        #expect(notice.kind == .invalidAddress(.hasCredentials))
        #expect(
            text(try #require(Words.notice(notice.kind)), in: "en")
                == "Leave the user name and password out of the address.")
        #expect(await harness.transport.requests.isEmpty)
    }
}
