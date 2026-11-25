import PurlayKit
import Testing

@testable import Purlay

@MainActor
@Suite("the app's environment")
struct EnvironmentTests {
    @Test("identifies itself to the server as an iOS client")
    func platform() {
        #expect(RealEnvironment.make().platform == .iOS)
    }
}
