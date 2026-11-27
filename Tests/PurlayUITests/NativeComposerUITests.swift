import UIKit
import XCTest

@MainActor
final class NativeComposerUITests: XCTestCase {
    func testSendEchoRetryAndWorkspaceScope() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let server = environment["PURLAY_COMPOSER_UITEST_SERVER"],
            let session = environment["PURLAY_COMPOSER_UITEST_SESSION"],
            let origin = URL(string: server)
        else { throw XCTSkip("provide the local composer fixture and its session") }

        continueAfterFailure = false
        let regular = UIDevice.current.userInterfaceIdiom == .pad
        if regular { XCUIDevice.shared.orientation = .landscapeLeft }
        let app = XCUIApplication()
        app.launchEnvironment["PURLAY_DEV_SERVER"] = server
        app.launchEnvironment["PURLAY_DEV_RESET"] = "1"
        app.launchEnvironment["PURLAY_DEV_SESSION"] = session
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let general = app.descendants(matching: .any)["chat.channel.00000000-0000-4000-8000-000000000011"].firstMatch
        XCTAssertTrue(general.waitForExistence(timeout: 20))
        general.tap()
        let field = app.descendants(matching: .any)["chat.composer"].firstMatch
        let send = app.buttons["chat.send"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        XCTAssertFalse(send.isEnabled)
        XCTAssertEqual(send.label, "Send Message")
        field.tap()
        field.typeText("   ")
        XCTAssertFalse(send.isEnabled, "space-only drafts must stay unsent")
        field.typeText("Hello from iOS")
        XCTAssertTrue(send.isEnabled)
        send.doubleTap()

        XCTAssertTrue(app.staticTexts["Hello from iOS"].waitForExistence(timeout: 4))
        let initialAttempts = try await sends(at: origin)
        let first = try XCTUnwrap(initialAttempts.first)
        XCTAssertEqual(initialAttempts.count, 1)
        let pending = app.descendants(matching: .any)["chat.pending.\(first.id)"].firstMatch
        let echo = app.descendants(matching: .any).matching(identifier: "chat.message.\(first.id)")
        XCTAssertTrue(pending.staticTexts["Hello from iOS"].exists, "the local row should appear before the echo")
        XCTAssertFalse(echo.firstMatch.exists)
        capture("Optimistic message")
        var release = URLRequest(url: origin.appending(path: "composer-echo"))
        release.httpMethod = "POST"
        let (_, response) = try await URLSession.shared.data(for: release)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 204)
        XCTAssertTrue(echo.firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(echo.firstMatch.staticTexts["Hello from iOS"].exists)
        XCTAssertEqual(echo.count, 1)
        XCTAssertFalse(pending.exists)
        XCTAssertFalse(send.isEnabled)

        field.tap()
        field.typeText("Try this again")
        send.tap()
        let retry = app.buttons["chat.outbox.retry"].firstMatch
        XCTAssertTrue(retry.waitForExistence(timeout: 7))
        XCTAssertTrue(app.staticTexts["Couldn’t send message."].exists)
        capture("Failed message")
        field.tap()
        field.typeText("Scoped draft")

        let switcher = app.buttons["workspace.switcher"]
        if !regular { app.navigationBars.buttons["Chat"].firstMatch.tap() }
        switcher.tap()
        app.buttons["Beacon Research"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["No Modules Available"].waitForExistence(timeout: 8))
        XCTAssertFalse(field.exists)
        XCTAssertFalse(retry.exists)
        switcher.tap()
        app.buttons["Alpha Studio"].firstMatch.tap()
        XCTAssertTrue(general.waitForExistence(timeout: 8))
        general.tap()
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        XCTAssertEqual(field.value as? String, "Scoped draft")
        XCTAssertTrue(retry.waitForExistence(timeout: 8), "the scoped outbox should reappear only in its own channel")
        retry.tap()
        let secondAttempts = try await sends(at: origin)
        let failed = try XCTUnwrap(secondAttempts.dropFirst().first)
        let recovered = app.descendants(matching: .any).matching(identifier: "chat.message.\(failed.id)")
        XCTAssertTrue(recovered.firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(recovered.firstMatch.staticTexts["Try this again"].exists)
        XCTAssertEqual(recovered.count, 1)
        XCTAssertFalse(retry.exists)
        capture("Reconciled messages")

        app.navigationBars.buttons["Chat"].firstMatch.tap()
        let announcements = app.descendants(matching: .any)["chat.channel.00000000-0000-4000-8000-000000000014"]
            .firstMatch
        XCTAssertTrue(announcements.waitForExistence(timeout: 5))
        announcements.tap()
        XCTAssertTrue(app.staticTexts["Only workspace owners and admins can post here."].waitForExistence(timeout: 7))
        XCTAssertFalse(field.exists)
        XCTAssertFalse(send.exists)

        let attempts = try await sends(at: origin)
        XCTAssertEqual(attempts.map(\.content), ["Hello from iOS", "Try this again", "Try this again"])
        XCTAssertEqual(attempts.map(\.channel), Array(repeating: "00000000-0000-4000-8000-000000000011", count: 3))
        XCTAssertEqual(attempts.dropFirst().first?.id, attempts.last?.id, "retry must reuse the original message ID")
    }

    private func sends(at origin: URL) async throws -> [Attempt] {
        let (data, response) = try await URLSession.shared.data(from: origin.appending(path: "composer-proof"))
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        return try JSONDecoder().decode([Attempt].self, from: data)
    }

    private struct Attempt: Decodable {
        let id: String
        let content: String
        let channel: String
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
