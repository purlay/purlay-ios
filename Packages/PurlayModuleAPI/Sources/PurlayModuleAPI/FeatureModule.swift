import SwiftUI

/// What a feature package gives the app for one server module.
///
/// A feature depends on this package and on the shared core, never on another feature: it reaches the others only
/// through what is declared here, as a server module reaches others only through the core's contracts.
@MainActor
public protocol FeatureModule: Identifiable where ID == ModuleID {
    /// The server module this feature draws. The app shows it only where the server runs it and the workspace may use it.
    var id: ModuleID { get }
    /// The name under the tab and at the top of the section.
    var title: LocalizedStringResource { get }
    /// An SF Symbol name.
    var systemImage: String { get }
    /// The section's root screen. The app owns the surrounding navigation container.
    func makeRoot() -> AnyView
}
