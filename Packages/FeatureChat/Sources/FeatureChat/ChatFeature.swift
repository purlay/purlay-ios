import PurlayModuleAPI
import SwiftUI

/// The shell's Chat destination uses the workspace's browser view until the native channel and feed screens ship.
@MainActor
public struct ChatFeature: FeatureModule {
    public let id: ModuleID = .chat
    public let title: LocalizedStringResource
    public let systemImage = "bubble.left.and.bubble.right"

    private let browserAction: LocalizedStringResource
    private let workspaceURL: URL

    public init(title: LocalizedStringResource, browserAction: LocalizedStringResource, workspaceURL: URL) {
        self.title = title
        self.browserAction = browserAction
        self.workspaceURL = workspaceURL
    }

    public func makeRoot() -> AnyView {
        AnyView(
            List {
                Link(destination: workspaceURL) {
                    Label {
                        Text(browserAction)
                    } icon: {
                        Image(systemName: "arrow.up.right.square")
                    }
                    .frame(minHeight: 44, alignment: .leading)
                }
            })
    }
}
