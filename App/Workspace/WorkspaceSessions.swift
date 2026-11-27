import Foundation
import Observation
import PurlayContract
import PurlayKit

/// iOS presents one of the connections owned by the Kit at a time. The Kit verifies workspace membership before
/// selecting it and keeps each connection's account and workspace scope.
@MainActor @Observable
final class WorkspaceSessions {
    private let sessions: DesktopSessions
    private var previous: AppModel?
    private var isSelecting = false
    private(set) var isSigningOut = false

    var isChangingSession: Bool { isSelecting || isSigningOut }

    var active: AppModel { sessions.active }

    init(_ environment: AppEnvironment) {
        sessions = DesktopSessions(environment)
    }

    func launch() async {
        await sessions.launch()
    }

    var choices: [Workspace] {
        guard active.phase == .ready, let me = active.me, !me.mustEnrolTwoFactor else { return [] }
        return me.memberships.map(\.workspace).sorted {
            let order = $0.name.localizedStandardCompare($1.name)
            return order == .orderedSame ? $0.slug < $1.slug : order == .orderedAscending
        }
    }

    var returnWorkspace: Workspace? {
        guard case .problem = active.phase, let previous, previous.phase == .ready else { return nil }
        return previous.workspace
    }

    func select(_ id: Uuid) async {
        let source = active
        guard !isChangingSession, source.workspace?.id != id, choices.contains(where: { $0.id == id }) else { return }
        previous = source
        isSelecting = true
        await sessions.selectWorkspace(id, from: source)
        isSelecting = false
    }

    func signOut(_ scope: SignOutScope) async {
        let source = active
        guard !isChangingSession, source.phase == .ready else { return }
        isSigningOut = true
        defer { isSigningOut = false }
        switch await source.signOut(scope) {
        case .done, .serverNotTold:
            previous = nil
        case .notDone, .credentialKept:
            break
        }
    }

    func returnToPreviousWorkspace() async {
        guard !isChangingSession, let id = returnWorkspace?.id, let previous else { return }
        isSelecting = true
        await sessions.selectWorkspace(id, from: previous)
        self.previous = nil
        isSelecting = false
    }
}
