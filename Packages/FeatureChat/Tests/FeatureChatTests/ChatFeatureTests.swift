import FeatureChat
import Foundation
import PurlayModuleAPI
import Testing

@MainActor
@Test("the shell registers the Chat destination under the server's chat ID")
func chatDestination() throws {
    let url = try #require(URL(string: "https://purlay.test/w/acme"))
    let feature = ChatFeature(title: "Chat", browserAction: "Open Chat in Browser", workspaceURL: url)
    let registry = ModuleRegistry([feature])
    #expect(registry.enabled(allowed: [.chat]).map(\.id) == [.chat])
    #expect(registry.enabled(allowed: [.issues]).isEmpty)
}
