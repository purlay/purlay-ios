/// The id a server module declares in its manifest (`chat`, `issues`, …), as `GET /api/me` spells it.
///
/// A string and not an enum: a server may run a module this build was made before, and an id this build does not
/// know must survive decoding and be ignored, never fail a launch (`API.md`, "Ignore what you do not know").
public struct ModuleID: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
}

extension ModuleID {
    public static let chat: ModuleID = "chat"
    public static let issues: ModuleID = "issues"
}
