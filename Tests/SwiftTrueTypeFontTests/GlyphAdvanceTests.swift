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
import SwiftPNG


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
		let glyphIndexes:[Int] = renderingFont.gylphIndexes(text: "abcdefgiI")
		XCTAssertEqual(glyphIndexes, [68,69,70,71,72,73,74,76,44])
		let advances:[SGFloat] = renderingFont.glyphAdvances(indices: glyphIndexes)
		print(advances)
		
	}
	
	
	func testSimpleGlyphPath() {
		let font = TestSamples.ubuntuRegular()
		let values:[FontOptionValue] = font.options.compactMap({ option in
			guard option.name == String.FontOptionNameSize else { return nil }
			return option.value(64.0)
		})
		guard let renderingFont:RenderingFont = font.rendering(options:values) else {
			XCTFail("unable to obtain rendering font")
			return
		}
//		let glyphIndexes:[Int] = renderingFont.gylphIndexes(text: "abcdefg")
//		XCTAssertEqual(glyphIndexes, [68,69,70,71,72,73,74])
//		let advances:[SGFloat] = renderingFont.glyphAdvances(indices: glyphIndexes)
		let aPath = renderingFont.path(glyphIndex: 68)
		let box = aPath.boundingBox!
		print(aPath.fastBoundingBox)
		let offsetTransformation = Transform2D(translateX: -box.origin.x, y: -box.origin.y + 0.01)
		let boxedPath = offsetTransformation.transform(aPath)
		let finalBox = boxedPath.fastBoundingBox!.roundedOut
		print(boxedPath)
		
		
		let colorSpace:ColorSpace = GenericRGBAColorSpace(hasAlpha: true)
		let context = SampledGraphicsContext(dimensions: finalBox.size, colorSpace: colorSpace)
		context.antialiasing = .subsampling(resolution: .three)
		context.drawPath(Transform2D(translateX: 1.0, y: 0.0).transform(Path(inRect:finalBox)), fillShader: SolidColorShader(color: colorSpace.white), stroke: nil)
		context.drawPath(boxedPath, fillShader: SolidColorShader(color: colorSpace.black), stroke: nil)
		
		
		guard let pngData = context.image.pngData else {
			XCTFail("couldn't get png data")
			return
		}
		let outputFilePath = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("test draw letter A.png")
		try? pngData.write(to: outputFilePath)
		
	}
	
	
	func testWordsRendering() {
		let font = TestSamples.ubuntuRegular()
		let values:[FontOptionValue] = font.options.compactMap({ option in
			guard option.name == String.FontOptionNameSize else { return nil }
			return option.value(17.0)
		})
		guard let renderingFont:RenderingFont = font.rendering(options:values) else {
			XCTFail("unable to obtain rendering font")
			return
		}
		
		//create a space to draw in
		let frame:Size = Size(width: 320.0, height: 44.0)
		
		let colorSpace:ColorSpace = GenericRGBAColorSpace(hasAlpha: true)
		let context = SampledGraphicsContext(dimensions: frame, colorSpace: colorSpace)
		context.antialiasing = .subsampling(resolution: .three)
		context.drawPath(Path(inRect:Rect(origin: .zero, size: frame)), fillShader: SolidColorShader(color: colorSpace.white), stroke: nil)
		
		context.currentState.applyTransformation(Transform2D(translateX: 30, y: 30))
		context.drawText("Ubuntu", font: renderingFont, fillShader: SolidColorShader(color: colorSpace.black), stroke: nil)
		
		guard let pngData = context.image.pngData else {
			XCTFail("couldn't get png data")
			return
		}
		let outputFilePath = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("ubuntu.png")
		try? pngData.write(to: outputFilePath)
	}
	
	
    static var allTests = [
        ("testMeasureGlyphAdvances", testMeasureGlyphAdvances),
    ]
}
