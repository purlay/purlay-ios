import PurlayContract
import PurlayKit
import SwiftUI

struct ChannelFeedView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    @State private var endVisible = false
    @State private var opening = false
    @State private var earlierFailed = false
    @State private var showOwnSend = false
    @State private var position = ScrollPosition(idType: Uuid.self)

    let scope: ChatScope
    let channelID: Uuid
    let words: ChatStrings

    private var model: AppModel { scope.model }
    private var channel: Channel? { scope.channel(channelID) }
    private var window: ChannelWindow? { model.chat.windows[channelID] }
    private var canPost: Bool { scope.canPost(in: channelID) }
    private var pending: [PendingMessage] {
        let current = window
        return model.selectedPending.filter { $0.channelID == channelID && current?.message($0.id) == nil }
    }

    var body: some View {
        // Loading and error transitions must not restart the channel screen's visibility task.
        ZStack {
            if channel == nil {
                ContentUnavailableView {
                    Label {
                        Text(words.channelUnavailable)
                    } icon: {
                        Image(systemName: "lock")
                    }
                }
            } else if let window {
                history(window, pending: pending)
            } else if model.channelLoadFailed.contains(channelID), !opening {
                ScrollView {
                    VStack(spacing: 16) {
                        ContentUnavailableView {
                            Label {
                                Text(words.messagesFailed)
                            } icon: {
                                Image(systemName: "exclamationmark.bubble")
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        Button {
                            Task { await open(force: true) }
                        } label: {
                            Text(words.tryAgain)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("chat.retry")
                        pendingRows(pending)
                    }
                    .padding()
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
                }
                .defaultScrollAnchor(.center, for: .alignment)
            } else {
                ProgressView { Text(words.loadingMessages) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if channel != nil, window != nil, model.selectedChannel == channelID {
                ChannelComposer(scope: scope, channelID: channelID, words: words) {
                    showOwnSend = true
                }
            }
        }
        .onChange(of: pending.last?.id) { _, id in
            if showOwnSend, let id {
                showOwnSend = false
                position.scrollTo(id: id, anchor: .bottom)
            }
        }
        .navigationTitle(Text(verbatim: channel?.title ?? ""))
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await open() }
        .onChange(of: scenePhase) { _, _ in updateReadVisibility() }
        .onChange(of: channel != nil) { _, _ in updateReadVisibility() }
        .onAppear {
            visible = true
            updateReadVisibility()
        }
        .onDisappear {
            visible = false
            updateReadVisibility()
        }
    }

    @ViewBuilder
    private func history(_ window: ChannelWindow, pending: [PendingMessage]) -> some View {
        if window.isEmpty && window.reachesOldest && pending.isEmpty {
            ContentUnavailableView {
                Label {
                    Text(words.noMessages)
                } icon: {
                    Image(systemName: "bubble.left")
                }
            }
            .onAppear { updateEndVisibility(true) }
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if !window.reachesOldest {
                        earlierControl
                    }
                    ForEach(window.messages.map(HistoryItem.delivered) + pending.map(HistoryItem.pending)) { item in
                        historyRow(item)
                            .id(item.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal)
                .padding(.vertical, 12)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            .defaultScrollAnchor(.top, for: .alignment)
            .scrollPosition($position)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.visibleRect.maxY >= geometry.contentSize.height - 2
            } action: { _, atEnd in
                updateEndVisibility(atEnd)
            }
            .onChange(of: window.messages.last?.id) { _, id in
                if endVisible, let tail = pending.last?.id ?? id {
                    position.scrollTo(id: tail, anchor: .bottom)
                }
            }
            .toolbar {
                if !endVisible {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            if window.reachesNewest {
                                position.scrollTo(edge: .bottom)
                            } else {
                                Task {
                                    await open(force: true)
                                    position.scrollTo(edge: .bottom)
                                }
                            }
                        } label: {
                            Label {
                                Text(words.jumpToLatest)
                            } icon: {
                                Image(systemName: "arrow.down")
                            }
                        }
                    }
                }
            }
        }
    }

    private enum HistoryItem: Identifiable {
        case delivered(Message)
        case pending(PendingMessage)

        var id: Uuid {
            switch self {
            case .delivered(let message): message.id
            case .pending(let message): message.id
            }
        }
    }

    @ViewBuilder
    private func historyRow(_ item: HistoryItem) -> some View {
        switch item {
        case .delivered(let message):
            MessageHistoryRow(message: message, words: words)
        case .pending(let message):
            PendingHistoryRow(message: message, words: words, retry: canPost ? { retry(message.id) } : nil)
        }
    }

    private func pendingRows(_ messages: [PendingMessage]) -> some View {
        ForEach(messages) { message in
            historyRow(.pending(message))
        }
    }

    private func retry(_ id: Uuid) {
        guard canPost, pending.contains(where: { $0.id == id && $0.delivery == .failed }) else { return }
        model.retry(id)
    }

    private var earlierControl: some View {
        VStack(alignment: .leading, spacing: 4) {
            if earlierFailed {
                Text(words.earlierFailed)
                    .foregroundStyle(.secondary)
            }
            if model.loadingOlder {
                ProgressView { Text(words.loadingEarlier) }
            } else {
                Button {
                    Task { await loadEarlier() }
                } label: {
                    Text(earlierFailed ? words.tryAgain : words.loadEarlier)
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("chat.loadEarlier")
            }
        }
    }

    private func open(force: Bool = false) async {
        guard !Task.isCancelled, channel != nil, !opening else { return }
        let alreadyOpen = model.selectedChannel == channelID && window != nil
        if !force && alreadyOpen {
            updateReadVisibility()
            return
        }
        opening = true
        defer { opening = false }
        model.setAtBottom(false)
        await model.showChannel(channelID)
        updateReadVisibility()
    }

    private func loadEarlier() async {
        guard visible, channel != nil, model.selectedChannel == channelID, !model.loadingOlder,
            let window, !window.reachesOldest, let first = window.messages.first?.id
        else { return }
        earlierFailed = false
        await model.loadOlder()
        guard visible, channel != nil, model.selectedChannel == channelID, let updated = self.window else { return }
        earlierFailed = !updated.reachesOldest && updated.messages.first?.id == first
        if updated.messages.first?.id != first {
            position.scrollTo(id: first, anchor: .top)
        }
    }

    private func updateEndVisibility(_ atEnd: Bool) {
        endVisible = atEnd
        updateReadVisibility()
    }

    private func updateReadVisibility() {
        guard model.selectedChannel == channelID else { return }
        let inFront = visible && channel != nil && scenePhase == .active
        model.setAtBottom(inFront && endVisible)
        model.setActive(inFront)
    }
}
