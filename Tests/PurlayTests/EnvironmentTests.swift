import Foundation
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

    @Test("reports the version the bundle says, not a placeholder")
    func version() throws {
        let shown = try #require(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
        #expect(RealEnvironment.make().appVersion == SemanticVersion(shown))
        #expect(RealEnvironment.make().appVersion != SemanticVersion(0, 0, 0))
    }

    @Test("keeps its files under the app's own name in Application Support")
    func dataDirectory() {
        let directory = RealEnvironment.make().dataDirectory
        #expect(directory.lastPathComponent == (Bundle.main.bundleIdentifier ?? "dev.purlay.ios"))
        #expect(directory.pathComponents.contains("Application Support"))
    }

    @Test("a timer fires once and a cancelled one never does")
    func schedule() async throws {
        let environment = RealEnvironment.make()
        var fired = 0
        _ = environment.schedule(10) { fired += 1 }
        let cancel = environment.schedule(10) { fired += 100 }
        cancel()
        for _ in 0..<200 where fired == 0 { try await Task.sleep(for: .milliseconds(10)) }
        try await Task.sleep(for: .milliseconds(50))
        #expect(fired == 1)
    }
}

@Suite("which server a build talks to (FR-006)")
struct ServerChoiceTests {
    @Test("a debug build talks to the development server it is told of, and may use plain HTTP to this machine")
    func debugBuild() {
        let choice = ServerChoice.resolve(isDebugBuild: true, override: "http://localhost:4390")
        #expect(choice == ServerChoice(address: "http://localhost:4390", allowsLocalHTTP: true))
    }

    @Test("a debug build told of nothing talks to the hosted server")
    func debugBuildWithoutOverride() {
        #expect(
            ServerChoice.resolve(isDebugBuild: true, override: nil)
                == ServerChoice(address: ServerAddress.hosted, allowsLocalHTTP: true))
    }

    @Test("a release build talks only to the hosted server over HTTPS, whatever it is handed")
    func releaseBuild() {
        for override in [nil, "http://localhost:4390", "https://elsewhere.example"] {
            let choice = ServerChoice.resolve(isDebugBuild: false, override: override)
            #expect(choice == ServerChoice(address: ServerAddress.hosted, allowsLocalHTTP: false))
        }
        #expect(ServerAddress.hosted.hasPrefix("https://"))
    }

    @MainActor
    @Test("the real environment follows the choice of the build it is in")
    func realEnvironment() {
        #if DEBUG
            let environment = RealEnvironment.make(variables: ["PURLAY_DEV_SERVER": "http://localhost:4390"])
            #expect(environment.serverAddress == "http://localhost:4390")
            #expect(environment.allowsLocalHTTP)
            #expect(RealEnvironment.make(variables: [:]).serverAddress == ServerAddress.hosted)
        #else
            let environment = RealEnvironment.make(variables: ["PURLAY_DEV_SERVER": "http://localhost:4390"])
            #expect(environment.serverAddress == ServerAddress.hosted)
            #expect(!environment.allowsLocalHTTP)
        #endif
    }
}

@Suite("what the app remembers between launches")
struct DefaultsOwnerTests {
    @Test("remembers who the retained data belongs to, and forgets it when told")
    func roundTrip() {
        let name = "purlay-tests-" + UUID().uuidString
        defer { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }
        let owner = DefaultsOwner(suite: name)
        #expect(owner.load() == nil)
        owner.save("user-1")
        #expect(owner.load() == "user-1")
        #expect(DefaultsOwner(suite: name).load() == "user-1", "a later launch finds it")
        owner.save(nil)
        #expect(owner.load() == nil)
    }
}

#if DEBUG
    @MainActor
    @Suite("the development shortcuts of a debug build")
    struct DevelopmentSessionTests {
        private let address = "http://localhost:4390"

        private func environment(_ sessions: InMemorySessionStore) -> AppEnvironment {
            Harness.environment(sessions: sessions)
        }

        private func stored(_ sessions: InMemorySessionStore) throws -> StoredSession? {
            try sessions.load(for: try ServerAddress.parse(address, allowsLocalHTTP: true))
        }

        @Test("stores the session it is handed for the server it names, so the screens after sign-in can be looked at")
        func seeds() throws {
            let sessions = InMemorySessionStore()
            RealEnvironment.seedDevelopmentSession(
                environment(sessions), variables: ["PURLAY_DEV_SERVER": address, "PURLAY_DEV_SESSION": "cookie-value"])
            #expect(try stored(sessions)?.cookie == "cookie-value")
        }

        @Test("stores nothing without a server to store it for, or without a session to store")
        func nothingToSeed() throws {
            let sessions = InMemorySessionStore()
            RealEnvironment.seedDevelopmentSession(
                environment(sessions), variables: ["PURLAY_DEV_SESSION": "cookie-value"])
            RealEnvironment.seedDevelopmentSession(environment(sessions), variables: ["PURLAY_DEV_SERVER": address])
            #expect(sessions.saves == 0)
        }

        @Test("an address it cannot use stores nothing, rather than a session for some other place")
        func unusableAddress() {
            let sessions = InMemorySessionStore()
            RealEnvironment.seedDevelopmentSession(
                environment(sessions),
                variables: ["PURLAY_DEV_SERVER": "ftp://x.test", "PURLAY_DEV_SESSION": "cookie-value"])
            #expect(sessions.saves == 0)
        }

        @Test("a keychain that refuses to forget the old session does not stop the new one being stored")
        func resetRefused() throws {
            let sessions = InMemorySessionStore()
            sessions.failDeletes()
            RealEnvironment.seedDevelopmentSession(
                environment(sessions),
                variables: ["PURLAY_DEV_SERVER": address, "PURLAY_DEV_RESET": "1", "PURLAY_DEV_SESSION": "fresh"])
            #expect(try stored(sessions)?.cookie == "fresh")
        }

        @Test("a reset forgets the stored session first")
        func reset() throws {
            let sessions = InMemorySessionStore()
            let server = try ServerAddress.parse(address, allowsLocalHTTP: true)
            try sessions.save(StoredSession(cookie: "old", expiresAt: nil, origin: server.description), for: server)
            RealEnvironment.seedDevelopmentSession(
                environment(sessions), variables: ["PURLAY_DEV_SERVER": address, "PURLAY_DEV_RESET": "1"])
            #expect(try stored(sessions) == nil)
        }
    }
#endif
