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
	static func openSans()->TrueTypeFont {
		let file = URL(fileURLWithPath: #file)
		let fontUrl = file.deletingLastPathComponent().appendingPathComponent("OpenSans-Regular.ttf")
		
		guard let fontData = try? Data(contentsOf: fontUrl) else {
			XCTFail("did not read font file data")
			fatalError()
		}
		do {
			let font = try TrueTypeFont(data: fontData)
			return font
		} catch {
			print(error)
			XCTFail("TrueTypeFont(data: did not open test file")
			fatalError()
		}
	}
	
	static func ubuntuRegular()->TrueTypeFont {
		let file = URL(fileURLWithPath: #file)
		let fontUrl = file.deletingLastPathComponent().appendingPathComponent("Ubuntu-Regular.ttf")
		
		guard let fontData = try? Data(contentsOf: fontUrl) else {
			XCTFail("did not read font file data")
			fatalError()
		}
		do {
			let font = try TrueTypeFont(data: fontData)
			return font
		} catch {
			print(error)
			XCTFail("TrueTypeFont(data: did not open test file")
			fatalError()
		}
	}
}
