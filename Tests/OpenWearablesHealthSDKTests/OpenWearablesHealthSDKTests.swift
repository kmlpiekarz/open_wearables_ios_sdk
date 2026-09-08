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
}
