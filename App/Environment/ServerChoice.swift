import PurlayKit

/// Which server a build talks to, and whether plain HTTP to this machine is acceptable. A pure function of two inputs the caller
/// fixes at compile time, so the rule is stated once and tested for both kinds of build: a release build talks only to the hosted
/// address, over HTTPS, whatever it is handed.
struct ServerChoice: Equatable {
    let address: String
    let allowsLocalHTTP: Bool

    /// `isDebugBuild` is a compile-time constant at the one call site, and `override` is read there only in a debug build.
    static func resolve(isDebugBuild: Bool, override: String?) -> ServerChoice {
        guard isDebugBuild else { return ServerChoice(address: ServerAddress.hosted, allowsLocalHTTP: false) }
        return ServerChoice(address: override ?? ServerAddress.hosted, allowsLocalHTTP: true)
    }
}
