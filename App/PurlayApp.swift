import SwiftUI

/// The shell: scenes and the composition root. What the app does lives in the packages.
@main
struct PurlayApp: App {
    @State private var sessions: WorkspaceSessions

    init() {
        let environment = RealEnvironment.make()
        #if DEBUG
            RealEnvironment.seedDevelopmentSession(environment)
        #endif
        _sessions = State(initialValue: WorkspaceSessions(environment))
    }

    var body: some Scene {
        WindowGroup {
            RootView(sessions: sessions)
                .task { await sessions.launch() }
        }
    }
}
