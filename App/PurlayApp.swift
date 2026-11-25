import PurlayKit
import SwiftUI

/// The shell: scenes and the composition root. What the app does lives in the packages.
@main
struct PurlayApp: App {
    @State private var model: AppModel

    init() {
        let environment = RealEnvironment.make()
        #if DEBUG
            RealEnvironment.seedDevelopmentSession(environment)
        #endif
        _model = State(initialValue: AppModel(environment))
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .task { await model.launch() }
        }
    }
}
