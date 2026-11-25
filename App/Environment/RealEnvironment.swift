import Foundation
import PurlayKit
import UIKit

/// The app's real environment: the Keychain, the defaults, the network, the browser and the files, as iOS gives them.
@MainActor
enum RealEnvironment {
    private static let keychainService = "dev.purlay.ios.session"
    private static let defaultDirectoryName = "dev.purlay.ios"

    static func make() -> AppEnvironment {
        let info = Bundle.main.infoDictionary
        let version =
            SemanticVersion(info?["CFBundleShortVersionString"] as? String ?? "") ?? SemanticVersion(0, 0, 0)
        let support =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = support.appendingPathComponent(
            Bundle.main.bundleIdentifier ?? defaultDirectoryName, isDirectory: true)
        #if DEBUG
            let allowsLocalHTTP = true
            let serverAddress = ProcessInfo.processInfo.environment["PURLAY_DEV_SERVER"] ?? ServerAddress.hosted
        #else
            let allowsLocalHTTP = false
            let serverAddress = ServerAddress.hosted
        #endif
        let platform = ClientPlatform.iOS
        let clientHeader = ClientHeader.value(appVersion: version, platform: platform)
        return AppEnvironment(
            transport: URLSessionTransport(), sessions: KeychainSessionStore(service: keychainService),
            preferences: UserDefaultsPreferences(), authenticator: WebAuthSession(), appVersion: version,
            platform: platform, deviceName: UIDevice.current.name, allowsLocalHTTP: allowsLocalHTTP,
            serverAddress: serverAddress, dataDirectory: directory,
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
        static func seedDevelopmentSession(_ environment: AppEnvironment) {
            let variables = ProcessInfo.processInfo.environment
            guard let server = variables["PURLAY_DEV_SERVER"],
                let address = try? ServerAddress.parse(server, allowsLocalHTTP: true)
            else { return }
            if variables["PURLAY_DEV_RESET"] == "1" { try? environment.sessions.delete(for: address) }
            guard let session = variables["PURLAY_DEV_SESSION"] else { return }
            try? environment.sessions.save(
                StoredSession(cookie: session, expiresAt: nil, origin: address.description), for: address)
        }
    }
#endif

/// Who the retained data belongs to, kept in the app's defaults beside it.
struct DefaultsOwner: OwnerMemory {
    private let key = "retained-data-owner"
    func load() -> String? { UserDefaults.standard.string(forKey: key) }
    func save(_ owner: String?) {
        if let owner {
            UserDefaults.standard.set(owner, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
