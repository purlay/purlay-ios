import PurlayContract
import PurlayKit
import SwiftUI

struct ChannelListView: View {
    let scope: ChatScope
    let words: ChatStrings

    var body: some View {
        let sections = scope.sections
        Group {
            if sections.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text(words.noChannels)
                    } icon: {
                        Image(systemName: "number")
                    }
                }
            } else {
                List(sections) { section in
                    Section {
                        ForEach(section.channels, id: \.id) { channel in
                            NavigationLink(value: channel.id) { row(channel) }
                                .accessibilityIdentifier("chat.channel.\(channel.id.value)")
                        }
                    } header: {
                        sectionLabel(section.kind)
                    }
                }
            }
        }
        .accessibilityIdentifier("chat.channels")
        .navigationDestination(for: Uuid.self) { channel in
            ChannelFeedView(scope: scope, channelID: channel, words: words)
        }
    }

    private func sectionLabel(_ kind: SidebarSection.Kind) -> Text {
        switch kind {
        case .starred: Text(words.starred)
        case .channels: Text(words.channels)
        case .conversations: Text(words.conversations)
        case .custom(_, let name): Text(verbatim: name)
        }
    }

    private func row(_ channel: Channel) -> some View {
        let unread = channel.state?.unreadCount ?? 0
        return HStack {
            Label {
                Text(verbatim: channel.title)
                    .fontWeight(channel.isUnread ? .semibold : .regular)
            } icon: {
                Image(systemName: symbol(for: channel))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if unread > 0 {
                Text(unread, format: .number)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityValue(unread > 0 ? Text(words.unread(unread)) : Text(verbatim: ""))
    }

    private func symbol(for channel: Channel) -> String {
        switch channel.type {
        case .private: "lock"
        case .directMessage: "person.crop.circle"
        default: "number"
        }
    }
}
