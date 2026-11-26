import PurlayKit

/// What stands on the screen for each phase of the app's model. A pure value, so each phase's screen is decided in one place and
/// tested without drawing anything: a person never stands in front of a state that is not one of these.
enum RootScreen: Equatable {
    /// Something is under way and the person waits: the words say what.
    case busy(Busy)
    case problem(ServerProblem)
    case signIn
    /// Signed in and the first screen has loaded. The module screens come with the shell; until then this says so.
    case ready

    enum Busy: Equatable {
        case connecting, signingIn, loading
    }

    init(_ phase: AppModel.Phase) {
        switch phase {
        case .launching, .checking: self = .busy(.connecting)
        case .signingIn: self = .busy(.signingIn)
        case .loading: self = .busy(.loading)
        case .problem(let problem): self = .problem(problem)
        case .signedOut: self = .signIn
        case .ready: self = .ready
        }
    }
}

/// What a tap on a screen does. A second tap that arrives before the first has changed the phase finds the phase changed, and does
/// nothing: one sign-in, one check, however fast the finger.
@MainActor
enum RootActions {
    static func signIn(_ model: AppModel) async {
        guard model.phase == .signedOut else { return }
        await model.signIn()
    }

    static func retry(_ model: AppModel) async {
        guard case .problem = model.phase else { return }
        await model.connect()
    }
}
