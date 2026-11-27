import PurlayContract
import SwiftUI

struct MessageHistoryRow: View {
    let message: Message
    let words: ChatStrings

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if Self.canShowBody(message) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        sender
                        time
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        sender
                        time
                    }
                }
                if !message.content.isEmpty {
                    Text(verbatim: message.content)
                        .textSelection(.enabled)
                }
                ForEach(message.attachments, id: \.id) { attachment in
                    Label {
                        Text(verbatim: attachment.fileName)
                    } icon: {
                        Image(systemName: "paperclip")
                    }
                    .foregroundStyle(.secondary)
                }
            } else {
                Text(words.messageUnavailable)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("chat.message.\(message.id.value)")
    }

    static func canShowBody(_ message: Message) -> Bool {
        message.hiddenForMe != true && message.historyHidden != true && message.deletedAt == nil
    }

    private var sender: some View {
        Group {
            if let author = message.sender {
                Text(verbatim: author.displayName)
            } else {
                Text(words.unknownSender)
            }
        }
        .font(.subheadline.weight(.semibold))
    }

    private var time: some View {
        Text(message.createdAt.date, format: .dateTime.month().day().hour().minute())
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
