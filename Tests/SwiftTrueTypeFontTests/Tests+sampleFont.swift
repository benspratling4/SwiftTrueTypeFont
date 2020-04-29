//
//  Tests+sampleFont.swift
//  SwiftTrueTypeFontTests
//
//  Created by Ben Spratling on 4/28/20.
//

import Foundation
import XCTest
@testable import SwiftTrueTypeFont

class TestSamples {
	static func openSans()->TTF {
		let file = URL(fileURLWithPath: #file)
		let fontUrl = file.deletingLastPathComponent().appendingPathComponent("OpenSans-Regular.ttf")
		
		guard let fontData = try? Data(contentsOf: fontUrl) else {
			XCTFail("did not read font file data")
			fatalError()
		}
		guard let font = try? TTF(data: fontData) else {
			XCTFail("TTF(data: did not open test file")
			fatalError()
		}
		return font
	}
}
