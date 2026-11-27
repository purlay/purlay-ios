import PurlayContract
import PurlayKit
import PurlayModuleAPI
import SwiftUI

/// The workspace's joined channels and their native message feeds.
@MainActor
public struct ChatFeature: FeatureModule {
    public let id: ModuleID = .chat
    public let title: LocalizedStringResource
    public let systemImage = "bubble.left.and.bubble.right"

    private let scope: ChatScope
    private let words: ChatStrings

    public init(model: AppModel, workspace: Uuid, title: LocalizedStringResource, words: ChatStrings) {
        self.scope = ChatScope(model: model, workspace: workspace)
        self.title = title
        self.words = words
    }

    public static func isAvailable(model: AppModel, workspace: Uuid) -> Bool {
        ChatScope(model: model, workspace: workspace).allowed
    }

    public func makeRoot() -> AnyView {
        AnyView(ChannelListView(scope: scope, words: words))
    }
}

/// All the routes in this feature take the workspace scope from the shell. A cached channel never supplies authority.
@MainActor
struct ChatScope {
    let model: AppModel
    let workspace: Uuid

    var allowed: Bool {
        guard model.phase == .ready, model.workspace?.id == workspace, let me = model.me,
            !me.mustEnrolTwoFactor, me.memberships.contains(where: { $0.workspace.id == workspace })
        else { return false }
        return model.chatAvailable
    }

    struct Section: Identifiable {
        let id: String
        let kind: SidebarSection.Kind
        let channels: [Channel]
    }

    var sections: [Section] {
        guard allowed else { return [] }
        return model.sidebar.compactMap { section in
            let channels = section.channels.filter { $0.workspaceId == workspace && $0.state != nil }
            return channels.isEmpty ? nil : Section(id: section.id, kind: section.kind, channels: channels)
        }
    }

    func canPost(in id: Uuid) -> Bool {
        channel(id) != nil && model.selectedChannel == id && model.canPostRoot(in: id)
    }

    func channel(_ id: Uuid) -> Channel? {
        guard allowed, let channel = model.chat.channels[id], channel.workspaceId == workspace,
            channel.state != nil
        else { return nil }
        return channel
    }
}

public struct ChatStrings: Sendable {
    let starred: LocalizedStringResource
    let channels: LocalizedStringResource
    let conversations: LocalizedStringResource
    let noChannels: LocalizedStringResource
    let channelUnavailable: LocalizedStringResource
    let noMessages: LocalizedStringResource
    let loadingMessages: LocalizedStringResource
    let messagesFailed: LocalizedStringResource
    let loadEarlier: LocalizedStringResource
    let loadingEarlier: LocalizedStringResource
    let earlierFailed: LocalizedStringResource
    let jumpToLatest: LocalizedStringResource
    let tryAgain: LocalizedStringResource
    let unknownSender: LocalizedStringResource
    let messageUnavailable: LocalizedStringResource
    let writeMessage: LocalizedStringResource
    let sendMessage: LocalizedStringResource
    let messageTooLong: LocalizedStringResource
    let channelReadOnly: LocalizedStringResource
    let sendingMessage: LocalizedStringResource
    let sentMessage: LocalizedStringResource
    let messageSendFailed: LocalizedStringResource
    let retryMessage: LocalizedStringResource
    let unread: @Sendable (Int) -> LocalizedStringResource

    public init(
        starred: LocalizedStringResource, channels: LocalizedStringResource, conversations: LocalizedStringResource,
        noChannels: LocalizedStringResource, channelUnavailable: LocalizedStringResource,
        noMessages: LocalizedStringResource, loadingMessages: LocalizedStringResource,
        messagesFailed: LocalizedStringResource,
        loadEarlier: LocalizedStringResource, loadingEarlier: LocalizedStringResource,
        earlierFailed: LocalizedStringResource,
        jumpToLatest: LocalizedStringResource, tryAgain: LocalizedStringResource,
        unknownSender: LocalizedStringResource,
        messageUnavailable: LocalizedStringResource,
        writeMessage: LocalizedStringResource, sendMessage: LocalizedStringResource,
        messageTooLong: LocalizedStringResource, channelReadOnly: LocalizedStringResource,
        sendingMessage: LocalizedStringResource, sentMessage: LocalizedStringResource,
        messageSendFailed: LocalizedStringResource, retryMessage: LocalizedStringResource,
        unread: @escaping @Sendable (Int) -> LocalizedStringResource
    ) {
        self.starred = starred
        self.channels = channels
        self.conversations = conversations
        self.noChannels = noChannels
        self.channelUnavailable = channelUnavailable
        self.noMessages = noMessages
        self.loadingMessages = loadingMessages
        self.messagesFailed = messagesFailed
        self.loadEarlier = loadEarlier
        self.loadingEarlier = loadingEarlier
        self.earlierFailed = earlierFailed
        self.jumpToLatest = jumpToLatest
        self.tryAgain = tryAgain
        self.unknownSender = unknownSender
        self.messageUnavailable = messageUnavailable
        self.writeMessage = writeMessage
        self.sendMessage = sendMessage
        self.messageTooLong = messageTooLong
        self.channelReadOnly = channelReadOnly
        self.sendingMessage = sendingMessage
        self.sentMessage = sentMessage
        self.messageSendFailed = messageSendFailed
        self.retryMessage = retryMessage
        self.unread = unread
    }
}
