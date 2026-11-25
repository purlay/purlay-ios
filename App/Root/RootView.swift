import PurlayKit
import SwiftUI

/// One screen per phase of the app's model: a person never stands in front of a state that is not one of these.
struct RootView: View {
    let model: AppModel

    var body: some View {
        switch model.phase {
        case .launching, .checking, .signingIn, .loading:
            ProgressView().controlSize(.large)
        case .problem(let problem):
            ContentUnavailableView(
                "Can't reach the server", systemImage: "wifi.exclamationmark",
                description: Text(String(describing: problem)))
        case .signedOut:
            SignInView(signIn: { await model.signIn() })
        case .ready:
            ContentUnavailableView("Signed in", systemImage: "checkmark.circle")
        }
    }
}

private struct SignInView: View {
    let signIn: () async -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Purlay").font(.largeTitle.bold())
            Button("Sign in", action: { Task { await signIn() } })
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }
}
