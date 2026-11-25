/// The features this build contains, in the order they appear, and the rule that decides which of them a person sees.
@MainActor
public struct ModuleRegistry {
    public let features: [any FeatureModule]

    /// - Precondition: ids are unique; two features for one server module is a programming error caught at launch.
    public init(_ features: [any FeatureModule]) {
        precondition(
            Set(features.map(\.id)).count == features.count, "two features were registered for one module id")
        self.features = features
    }

    /// The features to draw: those whose module the workspace may use, in the registry's own order.
    ///
    /// Ids the registry does not know are ignored without a word, and a module that is off is never inferred from a
    /// failed request: only `allowed`, read from the membership, decides.
    public func enabled(allowed: Set<ModuleID>) -> [any FeatureModule] {
        features.filter { allowed.contains($0.id) }
    }
}
