import Foundation
import OSLog
import PurlayKit
import UIKit

/// The app's real environment: the Keychain, the defaults, the network, the browser and the files, as iOS gives them.
@MainActor
enum RealEnvironment {
    private static let keychainService = "dev.purlay.ios.session"
    private static let defaultDirectoryName = "dev.purlay.ios"

    /// `variables`: the process's environment, handed in so a test can say what it holds.
    static func make(variables: [String: String] = ProcessInfo.processInfo.environment) -> AppEnvironment {
        let info = Bundle.main.infoDictionary
        let version =
            SemanticVersion(info?["CFBundleShortVersionString"] as? String ?? "") ?? SemanticVersion(0, 0, 0)
        let support =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = support.appendingPathComponent(
            Bundle.main.bundleIdentifier ?? defaultDirectoryName, isDirectory: true)
        // The development server is read in a debug build only: in a release build the name is not looked at.
        #if DEBUG
            let choice = ServerChoice.resolve(isDebugBuild: true, override: variables["PURLAY_DEV_SERVER"])
        #else
            let choice = ServerChoice.resolve(isDebugBuild: false, override: nil)
        #endif
        let platform = ClientPlatform.iOS
        let clientHeader = ClientHeader.value(appVersion: version, platform: platform)
        return AppEnvironment(
            transport: URLSessionTransport(), sessions: KeychainSessionStore(service: keychainService),
            preferences: UserDefaultsPreferences(), authenticator: WebAuthSession(), appVersion: version,
            platform: platform, deviceName: UIDevice.current.name, allowsLocalHTTP: choice.allowsLocalHTTP,
            serverAddress: choice.address, dataDirectory: directory,
            openSocket: { origin, session in
                URLSessionSocketTransport(origin: origin.description, clientHeader: clientHeader, cookie: { session })
                    .openSocket(session: session)
            },
            schedule: { milliseconds, work in
                let task = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(milliseconds))
                    if !Task.isCancelled { work() }
                }
                return { task.cancel() }
            },
            owner: DefaultsOwner())
    }
}

#if DEBUG
    extension RealEnvironment {
        /// Development shortcuts, in debug builds only, for the server `PURLAY_DEV_SERVER` names: `PURLAY_DEV_RESET=1` forgets
        /// its stored session first (a Keychain item outlives the app's launches), and `PURLAY_DEV_SESSION=<the cookie's
        /// value>` stores one already made, so the screens after sign-in can be looked at and tested without the browser.
        ///
        /// What cannot be done is logged, not swallowed: a developer who asked for a session and did not get one is told why.
        static func seedDevelopmentSession(
            _ environment: AppEnvironment, variables: [String: String] = ProcessInfo.processInfo.environment
        ) {
            guard let server = variables["PURLAY_DEV_SERVER"] else { return }
            let address: ServerAddress
            do {
                address = try ServerAddress.parse(server, allowsLocalHTTP: true)
            } catch {
                log.error("PURLAY_DEV_SERVER is not a usable address: \(String(describing: error))")
                return
            }
            if variables["PURLAY_DEV_RESET"] == "1" {
                do {
                    try environment.sessions.delete(for: address)
                } catch {
                    log.error("The stored session could not be forgotten: \(String(describing: error))")
                }
            }
            guard let session = variables["PURLAY_DEV_SESSION"] else { return }
            do {
                try environment.sessions.save(
                    StoredSession(cookie: session, expiresAt: nil, origin: address.description), for: address)
            } catch {
                log.error("The development session could not be stored: \(String(describing: error))")
            }
        }

        private static let log = Logger(subsystem: "dev.purlay.ios", category: "development")
    }
#endif

/// Who the retained data belongs to, kept in the app's defaults beside it.
struct DefaultsOwner: OwnerMemory {
    private let key = "retained-data-owner"
    private let suite: String?

    /// `suite`: a defaults domain a test makes for itself; the app's own (the standard one) when `nil`.
    init(suite: String? = nil) {
        self.suite = suite
    }

    private var defaults: UserDefaults { suite.flatMap { UserDefaults(suiteName: $0) } ?? .standard }

    func load() -> String? { defaults.string(forKey: key) }
    func save(_ owner: String?) {
        if let owner {
            defaults.set(owner, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
