//
//  GlyphAdvanceTests.swift
//  
//
//  Created by Ben Spratling on 5/25/20.
//

import Foundation
import XCTest
@testable import SwiftTrueTypeFont
import SwiftGraphicsCore


final class GlyphAdvanceTests: XCTestCase {
	
	func testMeasureGlyphAdvances() {
		let font = TestSamples.ubuntuRegular()
		let values:[FontOptionValue] = font.options.compactMap({ option in
			guard option.name == String.FontOptionNameSize else { return nil }
			return option.value(14.0)
		})
		guard let renderingFont:RenderingFont = font.rendering(options:values) else {
			XCTFail("unable to obtain rendering font")
			return
		}
		let glyphIndexes = renderingFont.gylphIndexes(text: "abcdefg")
		XCTAssertEqual(glyphIndexes, [68,69,70,71,72,73,74])
		
	}
	
	
    static var allTests = [
        ("testMeasureGlyphAdvances", testMeasureGlyphAdvances),
    ]
}
