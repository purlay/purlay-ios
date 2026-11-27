import PurlayContract
import PurlayKit
import SwiftUI

struct ChannelFeedView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    @State private var endVisible = false
    @State private var opening = false
    @State private var earlierFailed = false
    @State private var position = ScrollPosition(idType: Uuid.self)

    let scope: ChatScope
    let channelID: Uuid
    let words: ChatStrings

    private var model: AppModel { scope.model }
    private var channel: Channel? { scope.channel(channelID) }
    private var window: ChannelWindow? { model.chat.windows[channelID] }

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
                history(window)
            } else if model.channelLoadFailed.contains(channelID), !opening {
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
                }
            } else {
                ProgressView { Text(words.loadingMessages) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(Text(verbatim: channel?.title ?? ""))
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
    private func history(_ window: ChannelWindow) -> some View {
        if window.isEmpty && window.reachesOldest {
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
                    ForEach(window.messages, id: \.id) { message in
                        MessageHistoryRow(message: message, words: words)
                            .id(message.id)
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
            .onChange(of: window.messages.last?.id) { _, _ in
                if endVisible { position.scrollTo(edge: .bottom) }
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
