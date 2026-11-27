import Foundation
import PurlayContract
import PurlayKit
import Testing

@testable import Purlay

@MainActor
@Suite("the signed-in workspace shell")
struct WorkspaceShellTests {
    @Test(
        "an empty, unknown or denied module list opens the workspace without requesting chat",
        arguments: [
            (modules: [ModuleId](), grant: [ModuleId]?.none),
            (modules: [ModuleId.unknown("calendar")], grant: nil),
            (modules: [ModuleId.chat, .issues], grant: [.issues]),
        ])
    func coreOnly(modules: [ModuleId], grant: [ModuleId]?) async throws {
        let a = try workspace("Acme", slug: "acme", ending: "1")
        let fixture = try ShellFixture(modules: modules, memberships: [membership(a, grant)])
        await fixture.sessions.launch()

        #expect(fixture.sessions.active.phase == .ready)
        #expect(fixture.sessions.active.workspace?.id == a.id)
        #expect(fixture.sessions.choices == [a])
        #expect(WorkspaceDestinations.features(for: fixture.sessions.active).isEmpty)
        #expect(fixture.sockets.opened == 0)
        #expect(await fixture.transport.paths == ["/api/client", "/api/me"])
    }

    @Test("switching uses the selected membership and opens no chat connection for a workspace whose grant omits Chat")
    func switching() async throws {
        let chat = try workspace("Zulu Studio", slug: "zulu", ending: "1")
        let core = try workspace("Acme", slug: "acme", ending: "2")
        let unlisted = try workspace("Other", slug: "other", ending: "3")
        let fixture = try ShellFixture(
            modules: [.chat, .issues], memberships: [membership(chat, nil), membership(core, [.issues])])
        await fixture.sessions.launch()
        #expect(fixture.sessions.active.workspace?.id == chat.id)
        #expect(WorkspaceDestinations.features(for: fixture.sessions.active).map { $0.id.rawValue } == ["chat"])
        #expect(fixture.sessions.choices == [core, chat])
        #expect(fixture.sockets.opened == 1)

        await fixture.sessions.select(core.id)
        #expect(fixture.sessions.active.phase == .ready)
        #expect(fixture.sessions.active.workspace?.id == core.id)
        #expect(WorkspaceDestinations.features(for: fixture.sessions.active).isEmpty)
        #expect(fixture.sockets.opened == 1)
        #expect(await !fixture.transport.paths.contains { $0.contains(core.id.value) })

        let previousPaths = await fixture.transport.paths
        await fixture.sessions.select(core.id)
        await fixture.sessions.select(unlisted.id)
        #expect(fixture.sessions.active.workspace?.id == core.id)
        #expect(await fixture.transport.paths == previousPaths)
    }

    @Test("a failed switch can return to the previous ready workspace without a second sign-in")
    func recoverSwitch() async throws {
        let a = try workspace("Acme", slug: "acme", ending: "1")
        let b = try workspace("Beacon", slug: "beacon", ending: "2")
        let fixture = try ShellFixture(
            modules: [], memberships: [membership(a, nil), membership(b, nil)])
        await fixture.sessions.launch()
        let original = fixture.sessions.active
        await fixture.transport.failHandshake()
        await fixture.sessions.select(b.id)

        #expect(fixture.sessions.active.phase == .problem(.unreachable))
        #expect(fixture.sessions.returnWorkspace == a)
        await fixture.sessions.returnToPreviousWorkspace()
        #expect(fixture.sessions.active === original)
        #expect(fixture.sessions.active.workspace == a)
        #expect(fixture.sessions.returnWorkspace == nil)
    }

    @Test("no memberships and a two-factor hold expose no workspace destinations", arguments: [false, true])
    func noAvailableWorkspace(twoFactor: Bool) async throws {
        let a = try workspace("Acme", slug: "acme", ending: "1")
        let fixture = try ShellFixture(
            modules: [.chat], memberships: twoFactor ? [membership(a, nil)] : [], twoFactor: twoFactor)
        await fixture.sessions.launch()

        #expect(fixture.sessions.active.phase == .ready)
        #expect(fixture.sessions.active.workspace == nil)
        #expect(fixture.sessions.choices.isEmpty)
        #expect(WorkspaceDestinations.features(for: fixture.sessions.active).isEmpty)
        await fixture.sessions.select(a.id)
        #expect(fixture.sockets.opened == 0)
        #expect(await fixture.transport.paths == ["/api/client", "/api/me"])
    }

    private func workspace(_ name: String, slug: String, ending: String) throws -> Workspace {
        let id = try #require(Uuid("00000000-0000-4000-8000-00000000000" + ending))
        return Workspace(avatarUrl: nil, id: id, name: name, slug: slug)
    }

    private func membership(_ workspace: Workspace, _ modules: [ModuleId]?) -> Membership {
        Membership(
            deepWorkUntil: nil, joinedAt: Timestamp(Date(timeIntervalSince1970: 1_800_000_000)),
            modules: modules, role: .member, workspace: workspace)
    }
}

@MainActor
private struct ShellFixture {
    let transport: ShellTransport
    let sessions: WorkspaceSessions
    let sockets = SocketCounter()

    init(modules: [ModuleId], memberships: [Membership], twoFactor: Bool = false) throws {
        let user = CurrentUser(
            avatarUrl: nil, displayName: "Ada", email: "ada@purlay.test",
            id: try #require(Uuid("00000000-0000-4000-8000-000000000077")), username: "ada")
        let me = MeResponse(
            awayChosen: false, isServerAdmin: false, mayCreateWorkspace: false, memberships: memberships,
            modules: modules, mustEnrolTwoFactor: twoFactor, nameFromGitHub: false,
            profile: Profile(status: nil, timeZone: nil, title: nil), scheduledDeletions: [], user: user)
        transport = try ShellTransport(me: JSONEncoder().encode(me))
        let store = InMemorySessionStore()
        let server = try ServerAddress.parse("https://purlay.test")
        try store.save(
            StoredSession(cookie: "fixture-session", expiresAt: nil, origin: server.description), for: server)
        var environment = Harness.environment(transport: transport, sessions: store)
        let sockets = sockets
        environment.openSocket = { _, _ in { _, _ in sockets.open() } }
        sessions = WorkspaceSessions(environment)
    }
}

private actor ShellTransport: HTTPTransport {
    private let me: Data
    private var hasHandshake = true
    private(set) var paths: [String] = []

    init(me: Data) { self.me = me }

    func failHandshake() { hasHandshake = false }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        let path = request.url.path
        paths.append(path)
        if path == "/api/client" {
            guard hasHandshake else { throw TransportError.offline }
            switch Harness.clientInfo() {
            case .respond(let response): return response
            case .fail(let error): throw error
            }
        }
        let data = path == "/api/me" ? me : Data("[]".utf8)
        return HTTPResponse(status: 200, headers: ["content-type": "application/json"], body: data)
    }
}

@MainActor
private final class SocketCounter {
    private(set) var opened = 0

    func open() -> any SocketHandle {
        opened += 1
        return Stub()
    }

    private struct Stub: SocketHandle {
        func send(_ text: String) {}
        func close() {}
    }
}
