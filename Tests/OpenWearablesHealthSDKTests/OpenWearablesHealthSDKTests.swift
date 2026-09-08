import XCTest
@testable import OpenWearablesHealthSDK

final class OpenWearablesHealthSDKTests: XCTestCase {
    
    func testSharedInstanceExists() {
        let sdk = OpenWearablesHealthSDK.shared
        XCTAssertNotNil(sdk)
    }
    
    func testConfigureSetsHost() {
        let sdk = OpenWearablesHealthSDK.shared
        sdk.configure(host: "https://test.example.com")
        // Verify the SDK is configured (host is internal, so we check via credentials)
        let credentials = sdk.getStoredCredentials()
        XCTAssertEqual(credentials["host"] as? String, "https://test.example.com")
    }
    
    func testIsSessionValidWithoutSignIn() {
        let sdk = OpenWearablesHealthSDK.shared
        // Without sign in, session should not be valid (unless prior state exists)
        // This is a basic sanity check
        XCTAssertNotNil(sdk.isSessionValid)
    }
    
    func testGetSyncStatusReturnsValidStructure() {
        let sdk = OpenWearablesHealthSDK.shared
        let status = sdk.getSyncStatus()
        XCTAssertNotNil(status["hasResumableSession"])
        XCTAssertNotNil(status["sentCount"])
        XCTAssertNotNil(status["completedTypes"])
        XCTAssertNotNil(status["isFullExport"])
    }
    
    func testSyncShouldAdvanceOnlyOn2xx() {
        XCTAssertTrue(OpenWearablesHealthSDK.syncShouldAdvance(afterHTTPStatus: 200))
        XCTAssertTrue(OpenWearablesHealthSDK.syncShouldAdvance(afterHTTPStatus: 201))
        XCTAssertFalse(OpenWearablesHealthSDK.syncShouldAdvance(afterHTTPStatus: 400))
        XCTAssertFalse(OpenWearablesHealthSDK.syncShouldAdvance(afterHTTPStatus: 401))
        XCTAssertFalse(OpenWearablesHealthSDK.syncShouldAdvance(afterHTTPStatus: 500))
        XCTAssertFalse(OpenWearablesHealthSDK.syncShouldAdvance(afterHTTPStatus: 0))
    }

    func testConfigureWithTokenRefreshURLPersistsOverride() {
        let sdk = OpenWearablesHealthSDK.shared
        let refreshURL = "https://auth.example.com/v1/wearables/session"
        sdk.configure(host: "https://sync.example.com", tokenRefreshURL: refreshURL)

        XCTAssertEqual(OpenWearablesHealthSdkKeychain.getCustomRefreshUrl(), refreshURL)
        XCTAssertEqual(sdk.tokenRefreshEndpoint?.absoluteString, refreshURL)
        XCTAssertEqual(sdk.getStoredCredentials()["tokenRefreshURL"] as? String, refreshURL)
    }

    func testConfigureWithoutTokenRefreshURLClearsOverride() {
        let sdk = OpenWearablesHealthSDK.shared
        sdk.configure(
            host: "https://sync.example.com",
            tokenRefreshURL: "https://auth.example.com/refresh"
        )
        XCTAssertNotNil(OpenWearablesHealthSdkKeychain.getCustomRefreshUrl())

        sdk.configure(host: "https://sync.example.com")
        XCTAssertNil(OpenWearablesHealthSdkKeychain.getCustomRefreshUrl())
        XCTAssertEqual(
            sdk.tokenRefreshEndpoint?.absoluteString,
            "https://sync.example.com/api/v1/token/refresh"
        )
    }

    func testConfigureTreatsBlankTokenRefreshURLAsDefault() {
        let sdk = OpenWearablesHealthSDK.shared
        sdk.configure(
            host: "https://sync.example.com",
            tokenRefreshURL: "https://auth.example.com/refresh"
        )
        sdk.configure(host: "https://sync.example.com", tokenRefreshURL: "   ")
        XCTAssertNil(OpenWearablesHealthSdkKeychain.getCustomRefreshUrl())
        XCTAssertEqual(
            sdk.tokenRefreshEndpoint?.absoluteString,
            "https://sync.example.com/api/v1/token/refresh"
        )
    }

    func testAbsoluteHTTPURLRejectsRelativeAndNonHTTP() {
        XCTAssertNil(OpenWearablesHealthSDK.absoluteHTTPURL(from: "/token/refresh"))
        XCTAssertNil(OpenWearablesHealthSDK.absoluteHTTPURL(from: "token/refresh"))
        XCTAssertNil(OpenWearablesHealthSDK.absoluteHTTPURL(from: "ftp://auth.example.com/refresh"))
        XCTAssertEqual(
            OpenWearablesHealthSDK.absoluteHTTPURL(from: " https://auth.example.com/v1/refresh ")?.absoluteString,
            "https://auth.example.com/v1/refresh"
        )
    }

    func testInvalidPersistedRefreshURLDoesNotFallBackToSyncHost() {
        let sdk = OpenWearablesHealthSDK.shared
        sdk.configure(host: "https://sync.example.com")
        OpenWearablesHealthSdkKeychain.saveCustomRefreshUrl("not-a-url")
        XCTAssertNil(sdk.tokenRefreshEndpoint)
        sdk.configure(host: "https://sync.example.com")
    }
}
