import UIKit
import XCTest

/// This test uses a seeded server and a fresh local simulator session. The first listed workspace must
/// allow Chat. The second must omit Chat in the caller's membership.
@MainActor
final class WorkspaceShellUITests: XCTestCase {
    func testAdaptiveShellSwitchesToWorkspaceWithNoChat() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let server = environment["PURLAY_SHELL_UITEST_SERVER"], !server.isEmpty,
            let session = environment["PURLAY_SHELL_UITEST_SESSION"], !session.isEmpty,
            let chat = environment["PURLAY_SHELL_UITEST_CHAT_WORKSPACE"], !chat.isEmpty,
            let core = environment["PURLAY_SHELL_UITEST_CORE_WORKSPACE"], !core.isEmpty
        else {
            throw XCTSkip("provide the local workspace shell fixture and its names")
        }

        let regular = UIDevice.current.userInterfaceIdiom == .pad
        if regular { XCUIDevice.shared.orientation = .landscapeLeft }
        let app = XCUIApplication()
        app.launchEnvironment["PURLAY_DEV_SERVER"] = server
        app.launchEnvironment["PURLAY_DEV_RESET"] = "1"
        app.launchEnvironment["PURLAY_DEV_SESSION"] = session
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let switcher = app.buttons["workspace.switcher"]
        XCTAssertTrue(switcher.waitForExistence(timeout: 20), "the seeded session did not open the workspace shell")
        XCTAssertTrue(switcher.label.contains(chat))
        let chatDestination =
            regular
            ? app.descendants(matching: .any)["workspace.sidebar.chat"].firstMatch
            : app.tabBars.buttons["Chat"]
        XCTAssertTrue(chatDestination.exists, "the Chat destination did not use the appropriate navigation")
        let channels = app.descendants(matching: .any)["chat.channels"].firstMatch
        XCTAssertTrue(channels.exists)
        capture("Chat")

        switcher.tap()
        let target = app.buttons[core].firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 5), "the permitted second workspace is missing")
        target.tap()
        let empty = app.staticTexts["No Modules Available"].firstMatch
        XCTAssertTrue(empty.waitForExistence(timeout: 10), "the core-only workspace did not show its empty state")
        XCTAssertTrue(switcher.label.contains(core))
        XCTAssertFalse(chatDestination.exists)
        XCTAssertFalse(channels.exists)
        capture("Core workspace")

        switcher.tap()
        app.buttons[chat].firstMatch.tap()
        XCTAssertTrue(channels.waitForExistence(timeout: 10))
        XCTAssertTrue(switcher.label.contains(chat))
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
