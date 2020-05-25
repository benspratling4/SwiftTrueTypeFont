import XCTest
@testable import SwiftTrueTypeFont

final class NameTableTests: XCTestCase {
    func testEnglishPostScriptName() {
		XCTAssertEqual(TestSamples.openSans().name, "OpenSans")
    }

    static var allTests = [
        ("testEnglishPostScriptName", testEnglishPostScriptName),
    ]
}
