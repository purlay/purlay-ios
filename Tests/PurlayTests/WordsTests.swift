import Foundation
import PurlayContract
import PurlayKit
import Testing

@testable import Purlay

@Suite("the words of the screens, in both languages")
struct WordsTests {
    /// Every sentence a screen can say, with what it takes to say the dynamic ones.
    private static var everySentence: [LocalizedStringResource] {
        let problems: [ServerProblem] = [
            .unreachable, .notAPurlayServer, .rateLimited(retryAfter: 3),
            .appTooOld(ClientMinimum(appVersion: "9.0.0", contractVersion: nil, downloadUrl: nil)),
            .appTooOld(ClientMinimum(appVersion: nil, contractVersion: 2, downloadUrl: nil)),
            .serverTooOld(contract: 0),
            .unusableOrigin("ftp://x.test"),
        ]
        let signIns: [SignInError] = [
            .browserFailed("x"), .callbackRejected(.notOurs), .codeRejected, .rateLimited(retryAfter: nil),
            .refused(status: 403, code: .forbidden), .noSessionInAnswer, .unreachable(.offline),
            .storage(KeychainError(status: -25291, operation: "write")),
        ]
        let addresses: [ServerAddress.Problem] = [
            .empty, .unreadable, .notAWebAddress, .hasCredentials, .hasMoreThanAHost, .insecure,
        ]
        let notices: [Notice.Kind] =
            addresses.map { .invalidAddress($0) } + signIns.map { .signInFailed($0) } + [
                .sessionExpired, .sessionEndedByServer, .signedOutElsewhere,
                .sessionEndsSoon(Date(timeIntervalSince1970: 0)),
                .storageProblem, .originMismatch, .loadFailed,
            ]
        return Words.fixed + [Words.backToWorkspace("Acme"), Words.switchWorkspace("Acme")]
            + problems.flatMap { [Words.problem($0).title, Words.problem($0).detail] }
            + signIns.compactMap(Words.signIn) + notices.compactMap(Words.notice)
    }

    @Test("every sentence is translated: in Turkish it is not the English one")
    func translated() {
        for sentence in Self.everySentence {
            let english = text(sentence, in: "en")
            let turkish = text(sentence, in: "tr")
            #expect(!english.isEmpty && !turkish.isEmpty)
            #expect(turkish != english, "not translated: \(english)")
        }
    }

    @Test("a sentence that takes a value says it, in each language")
    func values() {
        let minimum = ClientMinimum(appVersion: "9.0.0", contractVersion: nil, downloadUrl: nil)
        #expect(text(Words.problem(.appTooOld(minimum)).detail, in: "en") == "It needs version 9.0.0 or newer.")
        #expect(text(Words.problem(.appTooOld(minimum)).detail, in: "tr").contains("9.0.0"))
        let without = ClientMinimum(appVersion: nil, contractVersion: 2, downloadUrl: nil)
        #expect(text(Words.problem(.appTooOld(without)).detail, in: "en") == "Update Purlay, then try again.")
        let ends = Words.notice(.sessionEndsSoon(Date(timeIntervalSince1970: 0)))
        #expect(ends.map { text($0, in: "en") }?.contains("Your session ends on") == true)
        #expect(ends.map { text($0, in: "tr") }?.contains("sona eriyor") == true)
    }

    @Test("the person closing the sign-in page is a choice: nothing is said of it")
    func cancelled() {
        #expect(Words.signIn(.cancelled) == nil)
        #expect(Words.notice(.signInFailed(.cancelled)) == nil)
    }

    @Test("a refusal these screens have no sentence for is said plainly, never as the case's name")
    func generic() throws {
        let words = try #require(Words.notice(.loadFailed))
        #expect(text(words, in: "en") == "Something went wrong. Try again.")
    }
}
