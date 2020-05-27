//
//  File.swift
//  
//
//  Created by Ben Spratling on 5/25/20.
//

import Foundation
import SwiftGraphicsCore

public class TrueTypeRenderingFont : RenderingFont {
	
	let trueTypeFont:TrueTypeFont
	let ppem:SGFloat
	init(font:TrueTypeFont, ppem:SGFloat, optionValues:[FontOptionValue]) {
		self.trueTypeFont = font
		self.ppem = ppem
		self.optionValues = optionValues
	}
	
	//MARK: - RenderingFont
	
	public var font:Font {
		return trueTypeFont
	}
	
	public var optionValues:[FontOptionValue]
	
	public func gylphIndexes(text:String)->[Int] {
		///currently only support unicode encoding 3 tables
		guard let table:CharacterEncodingTable = trueTypeFont.characterMapTable.tables.filter({ $0.encodingRecord.platformId == .unicode && $0.encodingRecord.encodingID == 3 }).first else {
			//return missing glyph for every thing
			return text.map { (chracter) -> Int in
				//for now, they're all the missing glyph
				//TODO: support actual character maps
				return 0
			}
		}
		
		return text.unicodeScalars.map { (character) -> Int in
			table.glyphIndex(characterIndex:Int(character.value))
		}
	}
	
	//basically, how wide is this character
	public func glyphAdvances(indices:[Int])->[SGFloat] {
		let glyphRanges:[Range<Int>] = indices.compactMap({ try? trueTypeFont.locationTable.rangeOfGlyph(at:$0) })
		let advances:[UInt16] = indices.map({ trueTypeFont.horizontalMetricsTable.advancedWidthsAndLeftSideBearings[$0].advanceWidth })
//		let boxes:[GlyphBox] = glyphRanges.compactMap({ try? trueTypeFont.glyphTable.boundingBox(in:$0) })
		return advances.map({  ppem * SGFloat($0) / SGFloat(trueTypeFont.headerTable.unitsPerEm) })
	}
	
	public func path(glyphIndex:Int)->Path {
		guard let range:Range<Int> = try? trueTypeFont.locationTable.rangeOfGlyph(at:glyphIndex)
			,trueTypeFont.glyphTable.hasGlyph(in: range)
			,let box:GlyphBox = try? trueTypeFont.glyphTable.boundingBox(in: range)
			,let contours:[[GlyphPoint]] = try? trueTypeFont.glyphTable.glyphContours(in:range, locationTable:trueTypeFont.locationTable)
			else {
				return Path()
		}
		let scale:SGFloat = ppem / SGFloat(trueTypeFont.headerTable.unitsPerEm)
		let xOffset:SGFloat = box.xMin
		
		//make paths out of the Glyph, then scale it
		var path = Path()
		
		for contour in contours {
			var controlPoint:Point? = nil
			//paths are implicitly closed, so we just add the first point onto the end
			var allPoints = contour
			allPoints.append(allPoints[0])
			for (pointIndex, point) in allPoints.enumerated() {
				let thisPoint:Point = Point(x: point.x, y: point.y)
				if pointIndex == 0 {
					if !point.isOnCurve {
						print("wait what?")
					}
					path.move(to: thisPoint)
				}
				else if point.isOnCurve {
					if let ctrlPoint = controlPoint {
						path.addCurve(near: ctrlPoint, to: thisPoint)
					} else {
						path.addLine(to: thisPoint)
					}
					controlPoint = nil
				}
				else {	//not on curve
					if let ctrlPoint = controlPoint {
						//there was an implicit on-curve point half way in between them
						let implicitOnCurvePoint = (thisPoint + ctrlPoint)/2.0
						path.addCurve(near: ctrlPoint, to: implicitOnCurvePoint)
					}
					controlPoint = thisPoint
				}
			}
			path.close()
	
		}

		//let moveTransform = Transform2D(translateX: -SGFloat(xOffset), y: 0.0)
		let scaleTransform:Transform2D = Transform2D(scaleX: scale, scaleY:-scale)
//		return moveTransform.concatenate(with: scaleTransform).transform(path)
		return scaleTransform.transform(path)
	}
	
	
	//TODO: write me
	
}
