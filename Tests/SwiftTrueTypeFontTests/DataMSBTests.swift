//
//  DataMSBTests.swift
//  SwiftTrueTypeFont
//
//  Created by Ben Spratling on 4/30/20.
//

import Foundation
@testable import SwiftTrueTypeFont
import XCTest



final class DataMSBTests : XCTestCase {
	func testMSBIntArrayReading() {
		let data = Data([0xFF, 0x00, 0x00, 0xFF])
		do {
			let shortInts:[UInt16] = try data.readMSBFixedWidthArray(at:0, count:2)
			XCTAssertEqual(shortInts[0], 0xFF00)
			XCTAssertEqual(shortInts[1], 0x00FF)
		} catch {
			XCTFail("unable to read data")
		}
		
	}
	
	
    static var allTests = [
        ("testMSBIntArrayReading", testMSBIntArrayReading),
    ]
}
