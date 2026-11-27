import Foundation
import PurlayContract
import Testing

@testable import FeatureChat

@MainActor
@Test("restricted, deleted or personally hidden message bodies are redacted")
func restrictedContent() throws {
    let id = try #require(Uuid("00000000-0000-4000-8000-000000000001"))
    let date = Timestamp(Date(timeIntervalSince1970: 1_800_000_000))
    var message = Message(
        attachments: [], channelId: id, content: "A real message", createdAt: date,
        deletedAt: nil, editedAt: nil, githubEvent: nil, id: id, mentions: [], parentId: nil,
        reactions: [], sender: nil, thread: nil)
    #expect(MessageHistoryRow.canShowBody(message))
    message.historyHidden = true
    #expect(!MessageHistoryRow.canShowBody(message))
    message.historyHidden = false
    message.hiddenForMe = true
    #expect(!MessageHistoryRow.canShowBody(message))
    message.hiddenForMe = false
    message.deletedAt = date
    #expect(!MessageHistoryRow.canShowBody(message))
}
