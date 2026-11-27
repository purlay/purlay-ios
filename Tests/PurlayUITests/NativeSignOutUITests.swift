import UIKit
import XCTest

@MainActor
final class NativeSignOutUITests: XCTestCase {
    func testThisDeviceEndsBothLocalSocketsAndLeavesTheOtherSessionActive() async throws {
        let fixture = try Fixture()
        let app = try await launch(fixture, mode: "hold")
        let switcher = app.buttons["workspace.switcher"]
        switcher.tap()
        app.buttons["Beacon Research"].firstMatch.tap()
        XCTAssertTrue(app.buttons["account.menu"].waitForExistence(timeout: 8))
        XCTAssertTrue(switcher.label.contains("Beacon Research"))
        let bothSockets = try await fixture.waitForSockets(2)
        XCTAssertEqual(bothSockets.openSockets, 2)

        app.buttons["account.menu"].tap()
        app.buttons["Sign Out on This Device"].tap()
        let pending = app.descendants(matching: .any)["account.signingOut"].firstMatch
        XCTAssertTrue(pending.waitForExistence(timeout: 6))
        XCTAssertFalse(app.buttons["account.menu"].exists)
        XCTAssertFalse(switcher.isEnabled)
        let before = try await fixture.state()
        XCTAssertEqual(before.logouts, ["/auth/logout"])
        XCTAssertTrue(before.deviceActive)

        try await fixture.control("release")
        assertSignIn(app)
        let after = try await fixture.waitForSockets(0)
        XCTAssertEqual(after.logouts, ["/auth/logout"])
        XCTAssertFalse(after.deviceActive)
        XCTAssertTrue(after.peerActive)
        XCTAssertGreaterThanOrEqual(after.closedSockets, 2)
        try await assertCredentialForgotten(app, fixture: fixture)
    }

    func testEverywhereCanBeCancelledAndRefusalKeepsTheCurrentSession() async throws {
        let fixture = try Fixture()
        let app = try await launch(fixture, mode: "refuse-everywhere-once")
        openEverywhereConfirmation(app).buttons["Cancel"].tap()
        let afterCancel = try await fixture.state()
        XCTAssertTrue(afterCancel.logouts.isEmpty)
        XCTAssertTrue(afterCancel.deviceActive)
        XCTAssertTrue(afterCancel.peerActive)

        openEverywhereConfirmation(app).buttons["account.confirmSignOutEverywhere"].firstMatch.tap()
        let refusal = app.staticTexts["Couldn’t sign out everywhere. Try again."]
        XCTAssertTrue(refusal.waitForExistence(timeout: 8))
        capture("Everywhere refused")
        let afterRefusal = try await fixture.state()
        XCTAssertEqual(afterRefusal.logouts, ["/auth/logout-all"])
        XCTAssertTrue(afterRefusal.deviceActive)
        XCTAssertTrue(afterRefusal.peerActive)
        XCTAssertEqual(afterRefusal.openSockets, 1)

        openEverywhereConfirmation(app).buttons["account.confirmSignOutEverywhere"].firstMatch.tap()
        assertSignIn(app)
        let after = try await fixture.waitForSockets(0)
        XCTAssertEqual(after.logouts, ["/auth/logout-all", "/auth/logout-all"])
        XCTAssertFalse(after.deviceActive)
        XCTAssertFalse(after.peerActive)
        try await assertCredentialForgotten(app, fixture: fixture)
    }

    func testOfflineThisDeviceSignsOutWithWarningAndNeverResumesTheCredential() async throws {
        let fixture = try Fixture()
        let app = try await launch(fixture, mode: "offline")
        try await fixture.control("pause")
        app.buttons["account.menu"].tap()
        app.buttons["Sign Out on This Device"].tap()
        assertSignIn(app)
        let warning = app.staticTexts["You signed out on this device. The server could not be notified."]
        XCTAssertTrue(warning.waitForExistence(timeout: 8))
        capture("Offline sign-out")

        try await fixture.control("resume")
        let after = try await fixture.state()
        XCTAssertTrue(after.logouts.isEmpty)
        XCTAssertTrue(after.deviceActive)
        XCTAssertTrue(after.peerActive)
        try await assertCredentialForgotten(app, fixture: fixture)
    }

    func testAccountMenuIsAvailableWithoutAWorkspace() async throws {
        let fixture = try Fixture()
        let app = try await launch(fixture, mode: "no-workspaces", sockets: 0)
        XCTAssertTrue(app.staticTexts["No Workspaces Yet"].exists)
        XCTAssertFalse(app.buttons["workspace.switcher"].exists)
        app.buttons["account.menu"].tap()
        app.buttons["Sign Out on This Device"].tap()
        assertSignIn(app)
        let after = try await fixture.state()
        XCTAssertEqual(after.logouts, ["/auth/logout"])
        XCTAssertFalse(after.deviceActive)
    }

    private func launch(_ fixture: Fixture, mode: String, sockets: Int = 1) async throws -> XCUIApplication {
        if UIDevice.current.userInterfaceIdiom == .pad { XCUIDevice.shared.orientation = .landscapeLeft }
        let app = XCUIApplication()
        if app.state != .notRunning { app.terminate() }
        try await fixture.control("reset/\(mode)")
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment = [
            "PURLAY_DEV_SERVER": fixture.server.absoluteString,
            "PURLAY_DEV_RESET": "1",
            "PURLAY_DEV_SESSION": fixture.session,
        ]
        app.launch()
        XCTAssertTrue(app.buttons["account.menu"].waitForExistence(timeout: 20))
        let initial = try await fixture.waitForSockets(sockets)
        XCTAssertEqual(initial.openSockets, sockets)
        return app
    }

    private func openEverywhereConfirmation(_ app: XCUIApplication) -> XCUIElement {
        let account = app.buttons["account.menu"]
        XCTAssertTrue(account.waitForExistence(timeout: 5))
        account.tap()
        app.buttons["Sign Out Everywhere…"].tap()
        let alert = app.alerts["Sign Out Everywhere"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts["This will end your Purlay sessions on all devices."].exists)
        return alert
    }

    private func assertSignIn(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Sign In with Browser"].waitForExistence(timeout: 12))
        XCTAssertFalse(app.buttons["account.menu"].exists)
    }

    private func assertCredentialForgotten(_ app: XCUIApplication, fixture: Fixture) async throws {
        let before = try await fixture.state()
        app.terminate()
        app.launchEnvironment = ["PURLAY_DEV_SERVER": fixture.server.absoluteString]
        app.launch()
        assertSignIn(app)
        let after = try await fixture.state()
        XCTAssertGreaterThan(after.handshakes, before.handshakes)
        XCTAssertEqual(
            after.authenticatedReads, before.authenticatedReads, "relaunch must not even try the stored credential")
        XCTAssertEqual(after.openSockets, 0)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private struct Fixture {
        let server: URL
        let controller: URL
        let session: String

        struct State: Decodable {
            let logouts: [String]
            let deviceActive: Bool
            let peerActive: Bool
            let openSockets: Int
            let closedSockets: Int
            let handshakes: Int
            let authenticatedReads: Int
        }

        init() throws {
            let environment = ProcessInfo.processInfo.environment
            guard let server = environment["PURLAY_SIGN_OUT_UITEST_SERVER"].flatMap(URL.init(string:)),
                let controller = environment["PURLAY_SIGN_OUT_UITEST_CONTROL"].flatMap(URL.init(string:)),
                let session = environment["PURLAY_SIGN_OUT_UITEST_SESSION"]
            else { throw XCTSkip("provide the local sign-out fixture and its controller") }
            self.server = server
            self.controller = controller
            self.session = session
        }

        func control(_ path: String) async throws {
            var request = URLRequest(url: controller.appending(path: path))
            request.httpMethod = "POST"
            let (_, response) = try await URLSession.shared.data(for: request)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 204)
        }

        func state() async throws -> State {
            let (data, response) = try await URLSession.shared.data(from: controller.appending(path: "state"))
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            return try JSONDecoder().decode(State.self, from: data)
        }

        func waitForSockets(_ count: Int) async throws -> State {
            var current = try await state()
            for _ in 0..<40 where current.openSockets != count {
                try await Task.sleep(for: .milliseconds(125))
                current = try await state()
            }
            return current
        }
    }
}
