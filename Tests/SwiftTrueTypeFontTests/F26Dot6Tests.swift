//
//  File.swift
//  
//
//  Created by Ben Spratling on 5/23/20.
//

import Foundation
import XCTest
@testable import SwiftTrueTypeFont

class F26Dot6Tests : XCTestCase {
	
	func testIntegerAddition() {
		let zero = F26Dot6(clamping:0)
		let one = F26Dot6(clamping:1)
		let two = F26Dot6(clamping:2)
		let three = F26Dot6(clamping:3)
		XCTAssertEqual(zero + one, one)
		XCTAssertEqual(one + one, two)
		XCTAssertEqual(two + one, three)
		XCTAssertEqual(one + two, three)
		
		XCTAssertEqual(zero * one, zero)
		XCTAssertEqual(one * one, one)
		XCTAssertEqual(one * two, two)
		XCTAssertEqual(one * three, three)
		
		XCTAssertEqual(one - one, zero)
		XCTAssertEqual(one - zero, one)
		XCTAssertEqual(three - one, two)
		XCTAssertEqual(two - one, one)
		
		XCTAssertEqual(two / two, one)
	}
	
	
	func testArithmetic() {
		let twelvePointFive:F26Dot6 = F26Dot6(approximate:12.5)
		let two:F26Dot6 = F26Dot6(approximate:2.0)
		let twentyFive:F26Dot6 = F26Dot6(approximate:25.0)
		XCTAssertEqual(twelvePointFive * two, twentyFive)
		XCTAssertEqual(twentyFive / two, twelvePointFive)
		
	}
	
	func testApproximateSet() {
		//F26Dot6(approximate: 1.0625)
		let seventeenSixteenths:F26Dot6 = F26Dot6(approximate:1.0625)
		let sixteen:F26Dot6 = F26Dot6(clamping:16)
		let seventeen:F26Dot6 = F26Dot6(clamping:17)
		XCTAssertEqual(seventeenSixteenths * sixteen, seventeen)
		
		
	}
	
	
	
	
	
	
	
	
	
	
}
