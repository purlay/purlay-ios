import UIKit
import XCTest

@MainActor
final class NativeChatUITests: XCTestCase {
    func testJoinedChannelsLoadNativeHistoryAndRetryEarlierPage() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let server = environment["PURLAY_CHAT_UITEST_SERVER"],
            let session = environment["PURLAY_CHAT_UITEST_SESSION"]
        else {
            throw XCTSkip("provide the chat history fixture and its local session")
        }

        if UIDevice.current.userInterfaceIdiom == .pad { XCUIDevice.shared.orientation = .landscapeLeft }
        let app = XCUIApplication()
        app.launchEnvironment["PURLAY_DEV_SERVER"] = server
        app.launchEnvironment["PURLAY_DEV_RESET"] = "1"
        app.launchEnvironment["PURLAY_DEV_SESSION"] = session
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let general = app.descendants(matching: .any)["chat.channel.00000000-0000-4000-8000-000000000011"].firstMatch
        XCTAssertTrue(general.waitForExistence(timeout: 20), "the joined channel never appeared")
        XCTAssertTrue(general.debugDescription.contains("3 unread"))
        XCTAssertFalse(app.staticTexts["Unjoined Lobby"].exists)
        general.tap()

        let newest = app.staticTexts["Newest message"]
        let previous = app.staticTexts["Previous message"]
        XCTAssertTrue(newest.waitForExistence(timeout: 10), "the latest page never opened")
        XCTAssertTrue(previous.exists)
        XCTAssertLessThan(previous.frame.minY, newest.frame.minY)

        let earlier = app.buttons["chat.loadEarlier"]
        XCTAssertTrue(earlier.exists)
        earlier.tap()
        XCTAssertTrue(app.staticTexts["Couldn’t load earlier messages."].waitForExistence(timeout: 5))
        app.buttons["chat.loadEarlier"].tap()
        let oldest = app.staticTexts["Earlier history"]
        if !oldest.isHittable {
            app.scrollViews.firstMatch.swipeDown()
        }
        XCTAssertTrue(oldest.waitForExistence(timeout: 5), "the older page was not prepended")
        XCTAssertLessThan(oldest.frame.minY, previous.frame.minY)
        XCTAssertFalse(app.staticTexts["Couldn’t load earlier messages."].exists)
        capture("Channel history")

        if UIDevice.current.userInterfaceIdiom == .pad,
            let original = environment["PURLAY_SHELL_UITEST_CHAT_WORKSPACE"],
            let other = environment["PURLAY_SHELL_UITEST_CORE_WORKSPACE"]
        {
            let switcher = app.buttons["workspace.switcher"]
            switcher.tap()
            app.buttons[other].firstMatch.tap()
            XCTAssertTrue(app.staticTexts["No Modules Available"].waitForExistence(timeout: 10))
            XCTAssertFalse(newest.exists)
            switcher.tap()
            app.buttons[original].firstMatch.tap()
        } else {
            app.navigationBars.buttons["Chat"].firstMatch.tap()
        }
        let quiet = app.descendants(matching: .any)["chat.channel.00000000-0000-4000-8000-000000000012"].firstMatch
        XCTAssertTrue(quiet.waitForExistence(timeout: 5))
        quiet.tap()
        XCTAssertTrue(app.staticTexts["Couldn’t Load Messages"].waitForExistence(timeout: 5))
        app.buttons["chat.retry"].tap()
        XCTAssertTrue(app.staticTexts["No Messages Yet"].waitForExistence(timeout: 10))
        XCTAssertFalse(newest.exists)
        capture("Empty history")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
