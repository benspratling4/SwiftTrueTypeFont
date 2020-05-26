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
			return option.value(34)
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
		let offsetTransformation = Transform2D(translateX: -box.origin.x + 1, y: -box.origin.y + 1)
		let boxedPath = offsetTransformation.transform(aPath)
		var finalBox = boxedPath.fastBoundingBox!.roundedOut
		finalBox.size.width += 2
		finalBox.size.height += 2
		print(boxedPath)
		
		
		let colorSpace:ColorSpace = GenericRGBAColorSpace(hasAlpha: true)
		let context = SampledGraphicsContext(dimensions: finalBox.size, colorSpace: colorSpace)
		context.antialiasing = .subsampling(resolution: .three)
		context.drawPath(Transform2D(translateX: 0.9, y: 0.0).transform(Path(inRect:finalBox)), fill: FillOptions(color: colorSpace.white), stroke: nil)
		context.drawPath(boxedPath, fill:FillOptions(color:colorSpace.black), stroke: nil)
		
		
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
			return option.value(34.0)
		})
		guard let renderingFont:RenderingFont = font.rendering(options:values) else {
			XCTFail("unable to obtain rendering font")
			return
		}
		
		//create a space to draw in
		let frame:Size = Size(width: 640, height: 88.0)
		
		let colorSpace:ColorSpace = GenericRGBAColorSpace(hasAlpha: true)
		let context = SampledGraphicsContext(dimensions: frame, colorSpace: colorSpace)
		context.antialiasing = .subsampling(resolution: .three)
		context.drawPath(Path(inRect:Rect(origin: .zero, size: frame)), fill:FillOptions(color:colorSpace.white), stroke: nil)
		
		context.currentState.applyTransformation(Transform2D(translateX: 20, y: 60))
		context.drawText("This is a simple sentence.", font: renderingFont, fillShader:SolidColorShader(color: colorSpace.black), stroke: nil)
		
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
