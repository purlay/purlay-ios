import SwiftUI

/// Where the system draws a floating control's background, named by what it is for and not by how it is drawn.
public enum SurfaceRole: Sendable {
    /// A bar or a group of controls floating over content: the navigation layer.
    case floatingControl
    /// A transient panel over content: a menu, a popover's body.
    case panel
}

extension View {
    /// A floating surface. From iOS 26 the system's Liquid Glass; before, a system material in the same shape.
    ///
    /// The one place an OS version decides how a surface looks: features call this and never write `#available`.
    /// Glass belongs on the navigation layer, never on content, so there is no role for a row or a card.
    @ViewBuilder
    public func purlaySurface(_ role: SurfaceRole, in shape: some Shape = Capsule()) -> some View {
        if #available(iOS 26, macOS 26, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(role.fallbackMaterial, in: shape)
        }
    }
}

extension SurfaceRole {
    fileprivate var fallbackMaterial: Material {
        switch self {
        case .floatingControl: .bar
        case .panel: .regularMaterial
        }
    }
}
