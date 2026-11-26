import PurlayKit
import SwiftUI

/// One screen per phase of the app's model, with what the model said to the person above it. Only system components: navigation
/// chrome and materials are the system's, and any OS-version branching would live in `PurlayDesign`, never here.
struct RootView: View {
    let model: AppModel

    var body: some View {
        screen
            .safeAreaInset(edge: .top, spacing: 0) { NoticeList(model: model) }
    }

    @ViewBuilder
    private var screen: some View {
        switch RootScreen(model.phase) {
        case .busy(let busy): BusyView(busy: busy)
        case .problem(let problem): ProblemView(problem: problem, retry: { await RootActions.retry(model) })
        case .signIn: SignInView(signIn: { await RootActions.signIn(model) })
        case .ready:
            ContentUnavailableView {
                Label(Words.signedInTitle, systemImage: "checkmark.circle")
            } description: {
                Text(Words.signedInDetail)
            }
        }
    }
}

/// Something is under way: a spinner, and in words what it is. Read as one thing by VoiceOver.
private struct BusyView: View {
    let busy: RootScreen.Busy

    var body: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large)
            Text(words).font(.headline).multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var words: LocalizedStringResource {
        switch busy {
        case .connecting: Words.connecting
        case .signingIn: Words.waitingForBrowser
        case .loading: Words.loadingWorkspace
        }
    }
}

/// The server cannot be used, and the one thing that can be done about it.
private struct ProblemView: View {
    let problem: ServerProblem
    let retry: () async -> Void

    var body: some View {
        let words = Words.problem(problem)
        Scrolling {
            ContentUnavailableView {
                Label(words.title, systemImage: "wifi.exclamationmark")
            } description: {
                Text(words.detail)
            } actions: {
                Button {
                    Task { await retry() }
                } label: {
                    Text(Words.tryAgain)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

private struct SignInView: View {
    let signIn: () async -> Void

    var body: some View {
        Scrolling {
            VStack(spacing: 24) {
                Text(verbatim: "Purlay").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                Text(Words.signInPrompt).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button {
                    Task { await signIn() }
                } label: {
                    Text(Words.signInButton)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
    }
}

/// What the model said that is not a screen of its own, one line each, each to be dismissed.
private struct NoticeList: View {
    let model: AppModel

    var body: some View {
        VStack(spacing: 8) {
            ForEach(model.notices) { notice in
                if let words = Words.notice(notice.kind) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(words).font(.callout).padding(.vertical, 12).frame(
                            maxWidth: .infinity, alignment: .leading)
                        Button {
                            model.dismiss(notice)
                        } label: {
                            Image(systemName: "xmark")
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(.rect)
                        }
                        .accessibilityLabel(Text(Words.dismiss))
                    }
                    .padding(.leading)
                    .background(.thinMaterial, in: .rect(cornerRadius: 12))
                    .padding(.horizontal)
                    .accessibilityElement(children: .contain)
                }
            }
        }
    }
}

/// Centres its content when it fits and scrolls when it does not (a large Dynamic Type size), instead of clipping.
private struct Scrolling<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                content.frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
