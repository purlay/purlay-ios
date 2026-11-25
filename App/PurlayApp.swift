import PurlayKit
import SwiftUI

/// The shell: scenes and the composition root. What the app does lives in the packages.
@main
struct PurlayApp: App {
    @State private var model = AppModel(RealEnvironment.make())

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .task { await model.launch() }
        }
    }
}
