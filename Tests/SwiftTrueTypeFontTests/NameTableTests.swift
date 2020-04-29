import XCTest
@testable import SwiftTrueTypeFont

final class NameTableTests: XCTestCase {
    func testEnglishPostScriptName() {
		XCTAssertEqual(TestSamples.openSans().nameTable?.englishPostScriptName, "OpenSans")
    }

    static var allTests = [
        ("testEnglishPostScriptName", testEnglishPostScriptName),
    ]
}
