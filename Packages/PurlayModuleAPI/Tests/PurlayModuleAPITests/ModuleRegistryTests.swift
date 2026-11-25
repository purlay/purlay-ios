import SwiftUI
import Testing

@testable import PurlayModuleAPI

@MainActor
private struct StubFeature: FeatureModule {
    let id: ModuleID
    var title: LocalizedStringResource { "Stub" }
    var systemImage: String { "circle" }
    func makeRoot() -> AnyView { AnyView(EmptyView()) }
}

@MainActor
@Suite("the module registry")
struct ModuleRegistryTests {
    private let registry = ModuleRegistry([StubFeature(id: .chat), StubFeature(id: .issues)])

    @Test("shows only what the workspace may use")
    func filtersByAllowed() {
        #expect(registry.enabled(allowed: [.chat]).map(\.id) == [.chat])
    }

    @Test("keeps the registry's order whatever order the server lists")
    func keepsOrder() {
        #expect(registry.enabled(allowed: [.issues, .chat]).map(\.id) == [.chat, .issues])
    }

    @Test("ignores a module this build has never heard of")
    func ignoresUnknown() {
        #expect(registry.enabled(allowed: ["time-tracking", .chat]).map(\.id) == [.chat])
    }

    @Test("shows nothing for the core alone")
    func coreOnly() {
        #expect(registry.enabled(allowed: []).isEmpty)
    }
}
