import Foundation
import Testing

@Suite("the privacy manifest the app ships")
struct PrivacyManifestTests {
    private func manifest() throws -> [String: Any] {
        let url = try #require(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        return try #require(plist as? [String: Any])
    }

    @Test("is in the app, and the app does not track")
    func doesNotTrack() throws {
        let manifest = try manifest()
        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect((manifest["NSPrivacyTrackingDomains"] as? [Any])?.isEmpty == true)
    }

    @Test("gives the reason for the one required-reason API the app uses: its own defaults")
    func declaresDefaults() throws {
        let declared = try #require(try manifest()["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        #expect(declared.count == 1)
        #expect(declared.first?["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults")
        #expect(declared.first?["NSPrivacyAccessedAPITypeReasons"] as? [String] == ["CA92.1"])
    }

    @Test("says what the server is sent, never for tracking, and only to make the app work")
    func collectedData() throws {
        let collected = try #require(try manifest()["NSPrivacyCollectedDataTypes"] as? [[String: Any]])
        let types = collected.compactMap { $0["NSPrivacyCollectedDataType"] as? String }
        #expect(
            Set(types) == [
                "NSPrivacyCollectedDataTypeName", "NSPrivacyCollectedDataTypeEmailAddress",
                "NSPrivacyCollectedDataTypeUserID", "NSPrivacyCollectedDataTypeOtherUserContent",
            ])
        for entry in collected {
            #expect(entry["NSPrivacyCollectedDataTypeTracking"] as? Bool == false)
            #expect(
                entry["NSPrivacyCollectedDataTypePurposes"] as? [String] == [
                    "NSPrivacyCollectedDataTypePurposeAppFunctionality"
                ])
        }
    }
}
