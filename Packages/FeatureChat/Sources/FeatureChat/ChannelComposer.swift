import PurlayContract
import PurlayKit
import SwiftUI

struct ChannelComposer: View {
    let scope: ChatScope
    let channelID: Uuid
    let words: ChatStrings
    let sent: () -> Void

    private var model: AppModel { scope.model }
    private var canPost: Bool { scope.canPost(in: channelID) }

    private var draft: Binding<String> {
        Binding(
            get: { model.draft(for: channelID) },
            set: { model.setDraft($0, for: channelID) })
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            if canPost {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 8) {
                        TextField(text: draft, axis: .vertical) {
                            Text(words.writeMessage)
                        }
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("chat.composer")
                        Button(action: send) {
                            Label {
                                Text(words.sendMessage)
                            } icon: {
                                Image(systemName: "arrow.up")
                            }
                            .labelStyle(.iconOnly)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .disabled(!canSend)
                        .accessibilityIdentifier("chat.send")
                    }
                    if tooLong {
                        Text(words.messageTooLong)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: 680)
            } else {
                Text(words.channelReadOnly)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(.background)
    }

    private var content: String { draft.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var tooLong: Bool { content.count > ContractConstants.messageContentMax }

    private var canSend: Bool {
        canPost && !content.isEmpty && !tooLong && model.canSend(text: content, channel: channelID, parent: nil)
    }

    private func send() {
        guard canSend, model.send(draft.wrappedValue) else { return }
        sent()
    }
}
