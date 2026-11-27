import XCTest

/// The sign-in as a person meets it, against a real server. These need one, so each is skipped unless the runner is given
/// `TEST_RUNNER_PURLAY_UITEST_SERVER` (a server this simulator trusts) and, for the second, `TEST_RUNNER_PURLAY_UITEST_SESSION`.
///
/// What is not driven here: approving inside the system browser's page. The sign-in sheet's address bar is read-only and
/// the simulator does not share Safari's cookies with it, so a test cannot sign a person in there. The server's half of
/// that step (authorise, one-time code, token) runs against a real server in purlay-swift's contract tests.
@MainActor
final class SignInFlowTests: XCTestCase {
    private let timeout: TimeInterval = 20

    private func environment(_ name: String) throws -> String {
        guard let value = ProcessInfo.processInfo.environment[name], !value.isEmpty else {
            throw XCTSkip("set TEST_RUNNER_\(name) to run this against a server")
        }
        return value
    }

    func testTheServersSignInPageOpensAndCancellingReturnsToSignedOut() throws {
        let server = try environment("PURLAY_UITEST_SERVER")
        let app = XCUIApplication()
        app.launchEnvironment["PURLAY_DEV_SERVER"] = server
        app.launchEnvironment["PURLAY_DEV_RESET"] = "1"
        app.launch()

        let signIn = app.buttons["Sign In with Browser"]
        XCTAssertTrue(signIn.waitForExistence(timeout: timeout), "the signed-out screen never appeared")
        signIn.tap()

        // The system asks once whether this app may sign in through the server's address.
        let alert = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.buttons["Continue"]
        if alert.waitForExistence(timeout: 5) { alert.tap() }

        XCTAssertTrue(
            app.staticTexts["Sign in to Purlay"].waitForExistence(timeout: timeout),
            "the server's sign-in page never opened\n\(app.debugDescription)")

        app.buttons["Close"].firstMatch.tap()
        XCTAssertTrue(signIn.waitForExistence(timeout: timeout), "cancelling did not return to the signed-out screen")
    }

    func testAStoredSessionOpensTheSignedInScreen() throws {
        let server = try environment("PURLAY_UITEST_SERVER")
        let session = try environment("PURLAY_UITEST_SESSION")
        let app = XCUIApplication()
        app.launchEnvironment["PURLAY_DEV_SERVER"] = server
        app.launchEnvironment["PURLAY_DEV_SESSION"] = session
        app.launch()

        let ready = app.descendants(matching: .any).matching(
            NSPredicate(
                format: "identifier IN %@",
                [
                    "workspace.switcher", "workspace.name", "workspace.emptyMemberships", "workspace.emptyModules",
                ]))
        XCTAssertTrue(ready.firstMatch.waitForExistence(timeout: timeout), "the workspace shell did not open")
    }
}
