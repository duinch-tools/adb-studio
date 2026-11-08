import XCTest
@testable import ADBStudio

final class ADBStudioTests: XCTestCase {
    func testLogLevelParsing() {
        XCTAssertEqual(LogLevel.from(tag: "V"), .verbose)
        XCTAssertEqual(LogLevel.from(tag: "D"), .debug)
        XCTAssertEqual(LogLevel.from(tag: "I"), .info)
        XCTAssertEqual(LogLevel.from(tag: "W"), .warn)
        XCTAssertEqual(LogLevel.from(tag: "E"), .error)
        XCTAssertEqual(LogLevel.from(tag: "F"), .assert)
        XCTAssertEqual(LogLevel.from(tag: "A"), .assert)
        XCTAssertEqual(LogLevel.from(tag: "UNKNOWN"), .verbose)
    }
    
    func testDeviceDisplayName() {
        let dev = AdbDevice(id: "emulator-5554", model: "Pixel_7_Pro")
        XCTAssertEqual(dev.displayName, "Pixel_7_Pro (emulator-5554)")
    }
    
    func testAppTabAttributes() {
        XCTAssertEqual(AppTab.screenshot.iconName, "camera.fill")
        XCTAssertEqual(AppTab.recording.iconName, "record.circle.fill")
        XCTAssertEqual(AppTab.logcat.iconName, "terminal.fill")
    }
}
