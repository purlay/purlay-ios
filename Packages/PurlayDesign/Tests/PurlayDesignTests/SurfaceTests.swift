import SwiftUI
import Testing

@testable import PurlayDesign

@MainActor
@Suite("surfaces")
struct SurfaceTests {
    @Test("a surface can be built for every role and shape")
    func buildsEverywhere() {
        for role in [SurfaceRole.floatingControl, .panel] {
            _ = Text("x").purlaySurface(role)
            _ = Text("x").purlaySurface(role, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
