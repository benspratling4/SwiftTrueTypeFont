//
//  File.swift
//  
//
//  Created by Ben Spratling on 5/24/20.
//

import Foundation
import SwiftGraphicsCore

enum GlyphError : Error {
	case unsupportedFeature
}

struct GlyphTable {
	
	init(data:Data, in range:Range<Int>)throws {
		subData = Data(data[range])
	}
	
	var subData:Data
	
	
	///call this before the other glyph methods to determine if there really is a glyph there
	func hasGlyph(in range:Range<Int>)->Bool {
		return range.upperBound != range.lowerBound
	}
	
	
	///in f units
	func boundingBox(in range:Range<Int>)throws->GlyphBox {
		let start:Int = range.lowerBound
		let xMin:Int16 = try subData.readMSBFixedWidthInt(at: start + 2)
		let yMin:Int16 = try subData.readMSBFixedWidthInt(at: start + 4)
		let xMax:Int16 = try subData.readMSBFixedWidthInt(at: start + 6)
		let yMax:Int16 = try subData.readMSBFixedWidthInt(at: start + 8)
		return GlyphBox(xMin:SGFloat(xMin)
			,yMin:SGFloat(yMin)
			,xMax:SGFloat(xMax)
			,yMax:SGFloat(yMax))
	}
	
	func isGlyphCompound(in range:Range<Int>)throws->Bool {
		if range.upperBound == range.lowerBound {
			return false
		}
		let numberOfCounters:Int16 = try subData.readMSBFixedWidthInt(at: range.lowerBound)
		return numberOfCounters < 0
	}
	
	func glyphContours(in range:Range<Int>, locationTable:LocationTable)throws->[[GlyphPoint]] {
		if try isGlyphCompound(in: range) {
			return try compoundGlyphContours(in: range, locationTable: locationTable)
		} else {
			return try simpleGlyphContours(in: range)
		}
	}
	
	//each contour is an array of points
	internal func simpleGlyphContours(in range:Range<Int>)throws->[[GlyphPoint]] {
		let start:Int = range.lowerBound
		let numberOfCounters:Int16 = try subData.readMSBFixedWidthInt(at: start)
		let isCompound:Bool = numberOfCounters < 0
		let contourCount:Int = Int(numberOfCounters) * (isCompound ? -1 : 1)
		if isCompound {
			//TODO: throw error, this method is for simple glyphs only
			fatalError("this method is for simple glyphs only")
		}
		var dataIndex:Int = start + 10
		
		var indicesOfContourEndpoints:[UInt16] = [UInt16](repeating: 0, count: contourCount)
		for i in 0..<contourCount {
			indicesOfContourEndpoints[i] = try subData.readMSBFixedWidthUInt(at: dataIndex)
			dataIndex += 2
		}
		let instructionLength:UInt16 = try subData.readMSBFixedWidthUInt(at: dataIndex)
		dataIndex += 2
		dataIndex += Int(instructionLength)
		
		//parse flag bytes
		var pointFlags:[GlyphFlags] = []
		var flagIndex:Int = 0
		while flagIndex <= indicesOfContourEndpoints.last! {
			let flags:GlyphFlags = GlyphFlags(rawValue: subData[dataIndex])
			dataIndex += 1
			pointFlags.append(flags)
			flagIndex += 1
			if flags.contains(.repeats) {
				let repeatCount:UInt8 = subData[dataIndex]
				dataIndex += 1
				pointFlags.append(contentsOf:[GlyphFlags](repeating: flags, count: Int(repeatCount)) )
				flagIndex += Int(repeatCount)
			}
		}
		
		var xCoords:[Int16] = [] //TODO: make me more efficient by pre-allocating the space for the coords
		for flags in pointFlags {
			let newX:Int16
			if flags.contains(.xIsShort) {
				let xByte:UInt8 = subData[dataIndex]
				dataIndex += 1
				let shortX:UInt16 = UInt16(xByte)
				let signedX:Int16 = Int16(bitPattern: shortX)
				let isNegative:Bool = !flags.contains(.shortXSign)
				newX = isNegative ? -1 * signedX : signedX
			} else if flags.contains(.xIsTheSame) {
				//repeat old value
				newX = 0
			} else {
				//read int16 from data
				newX = try subData.readMSBFixedWidthInt(at: dataIndex)
				dataIndex += 2
			}
			xCoords.append(newX + (xCoords.last ?? 0) )
		}
		
		var yCoords:[Int16] = [] //TODO: make me more efficient by pre-allocating the space for the coords
		for flags in pointFlags {
			let newY:Int16
			if flags.contains(.yIsShort) {
				let yByte:UInt8 = subData[dataIndex]
				dataIndex += 1
				let shortY:UInt16 = UInt16(yByte)
				let signedY:Int16 = Int16(bitPattern: shortY)
				let isNegative:Bool = !flags.contains(.shortYSign)
				newY = isNegative ? -1 * signedY : signedY
			} else if flags.contains(.yIsTheSame) {
				//repeat old value
				newY = 0
			} else {
				//read int16 from data
				newY = try subData.readMSBFixedWidthInt(at: dataIndex)
				dataIndex += 2
			}
			yCoords.append( newY + (yCoords.last ?? 0) )
		}
		
		//now transform flags x and y into contours and points
		var contours:[[GlyphPoint]] = []
		var points:[GlyphPoint] = []
		for (pointIndex, flags) in pointFlags.enumerated() {
			points.append(GlyphPoint(x:SGFloat(xCoords[pointIndex])
				,y:SGFloat(yCoords[pointIndex])
				,isOnCurve: flags.contains(.pointIsOnCurve)))
			if pointIndex == indicesOfContourEndpoints[0] {
				_ = indicesOfContourEndpoints.removeFirst()
				contours.append(points)
				points = []
			}
		}
		return contours
	}
	
	
	///compound glyphs need to be able to find other glyphs, so we have to give it the location table
	internal func compoundGlyphContours(in range:Range<Int>, locationTable:LocationTable)throws->[[GlyphPoint]] {
		let start:Int = range.lowerBound
		let end:Int = range.upperBound
		if end == start {
			fatalError("change me to throw an error")
		}
		var dataIndex:Int = start + 10
		var allContours:[[GlyphPoint]] = []
		
		func point(in contours:[[GlyphPoint]], at index:Int)->Point {
			var p:Int = 0
			for contour in contours {
				for point in contour {
					if p == index {
						return Point(x: point.x, y: point.y)
					}
					p += 1
				}
			}
			return .zero
		}
		
		
		var flags:CompoundGlyphFlags = CompoundGlyphFlags(rawValue: 0)
		repeat {
			//get the flags
			let flagsWord:UInt16 = try subData.readMSBFixedWidthUInt(at: dataIndex)
			dataIndex += 2
			flags = CompoundGlyphFlags(rawValue: flagsWord)
			
			//get the glyph
			let glyphIndex:UInt16 = try subData.readMSBFixedWidthUInt(at: dataIndex)
			dataIndex += 2
			let componentRange:Range<Int> = try locationTable.rangeOfGlyph(at: Int(glyphIndex))
			if !hasGlyph(in:componentRange) {
				continue
			}
			let componentContours:[[GlyphPoint]]
			if try isGlyphCompound(in: componentRange) {
				componentContours = try compoundGlyphContours(in: componentRange, locationTable: locationTable)
			} else {
				componentContours = try simpleGlyphContours(in: componentRange)
			}
			
			func parseTransformationQuadruple()throws->(a:SGFloat, b:SGFloat, c:SGFloat, d:SGFloat, m:SGFloat, n:SGFloat) {
				let aFloat:SGFloat
				let bFloat:SGFloat
				let cFloat:SGFloat
				let dFloat:SGFloat
				
				if flags.contains(.twoByTwoTransformationMatrix) {
					let a:Int16 = try subData.readMSBFixedWidthInt(at: dataIndex)
					dataIndex += 2
					let b:Int16 = try subData.readMSBFixedWidthInt(at: dataIndex)
					dataIndex += 2
					let c:Int16 = try subData.readMSBFixedWidthInt(at: dataIndex)
					dataIndex += 2
					let d:Int16 = try subData.readMSBFixedWidthInt(at: dataIndex)
					dataIndex += 2
					aFloat = F2Dot14(bitPattern:a).floatValue
					bFloat = F2Dot14(bitPattern:b).floatValue
					cFloat = F2Dot14(bitPattern:c).floatValue
					dFloat = F2Dot14(bitPattern:d).floatValue
				}
				else if flags.contains(.differentXAndYScales) {
					let a:Int16 = try subData.readMSBFixedWidthInt(at: dataIndex)
					dataIndex += 2
					let d:Int16 = try subData.readMSBFixedWidthInt(at: dataIndex)
					dataIndex += 2
					aFloat = F2Dot14(bitPattern:a).floatValue
					bFloat = 0
					cFloat = 0
					dFloat = F2Dot14(bitPattern:d).floatValue
				}
				else if flags.contains(.transformationIncludesScale) {
					let a:Int16 = try subData.readMSBFixedWidthInt(at: dataIndex)
					dataIndex += 2
					aFloat = F2Dot14(bitPattern:a).floatValue
					bFloat = 0
					cFloat = 0
					dFloat = F2Dot14(bitPattern:a).floatValue
				} else {
					aFloat = 1
					bFloat = 0
					cFloat = 0
					dFloat = 1
				}
				let m0:SGFloat = max(abs(aFloat), abs(bFloat))
				let n0:SGFloat = max(abs(cFloat), abs(dFloat))
				
				let m:SGFloat
				let n:SGFloat
				
				if abs(abs(aFloat)-abs(cFloat)) <= 33.0/65536 {
					m = 2.0 * m0
				} else {
					m = m0
				}
				
				if abs(abs(bFloat)-abs(dFloat)) <= 33.0/65536 {
					n = 2.0 * n0
				} else {
					n = n0
				}
				return (aFloat, bFloat, cFloat, dFloat, m, n)
			}
			
			
			if flags.contains(.argsAreXYValues) {
				//parse actual x,y coordinates
				let dx:SGFloat
				let dy:SGFloat
				if flags.contains(.arg1And2AreWords) {
					let xShort:Int16 = try subData.readMSBFixedWidthInt(at: dataIndex)
					dataIndex += 2
					dx = SGFloat(xShort)
					let yShort:Int16 = try subData.readMSBFixedWidthInt(at: dataIndex)
					dataIndex += 2
					dy = SGFloat(yShort)
				} else {
					//x, y are bytes
					let e:Int8 = try subData.readMSBFixedWidthInt(at: dataIndex)
					dataIndex += 1
					let f:Int8 = try subData.readMSBFixedWidthInt(at: dataIndex)
					dataIndex += 1
					dx = SGFloat(e)
					dy = SGFloat(f)
				}
				//now transform the new glyph component points and add the contours
				let (a, b, c, d, m, n) = try parseTransformationQuadruple()
				let aOverM = a/m
				let cOverM = c/m
				let bOverN = b/n
				let dOverN = d/n
				
				func transformation(_ point:GlyphPoint)->GlyphPoint {
					return GlyphPoint(x: m * (dx + aOverM * point.x + cOverM * point.y )
						,y: n * (dy + bOverN * point.x + dOverN * point.y )
						,isOnCurve: point.isOnCurve)
				}
				
				let transformedComponentContours:[[GlyphPoint]] = componentContours.map({
					return $0.map(transformation)
				})
				
				allContours.append(contentsOf: transformedComponentContours)
			} else {
				//parse indexes of two points
				let indexOfMatchingPointInCompoundBeingConstructed:Int
				let indexOfMatchingPointInComponent:Int
				if flags.contains(.arg1And2AreWords) {
					let xShort:UInt16 = try subData.readMSBFixedWidthUInt(at: dataIndex)
					dataIndex += 2
					let yShort:UInt16 = try subData.readMSBFixedWidthUInt(at: dataIndex)
					dataIndex += 2
					indexOfMatchingPointInCompoundBeingConstructed = Int(xShort)
					indexOfMatchingPointInComponent = Int(yShort)
				} else {
					//x, y are bytes
					let xByte:UInt8 = try subData.readMSBFixedWidthUInt(at: dataIndex)
					dataIndex += 1
					let yByte:UInt8 = try subData.readMSBFixedWidthUInt(at: dataIndex)
					dataIndex += 1
					indexOfMatchingPointInCompoundBeingConstructed = Int(xByte)
					indexOfMatchingPointInComponent = Int(yByte)
				}
				
				let (a, b, c, d, m, n) = try parseTransformationQuadruple()
				let aOverM = a/m
				let cOverM = c/m
				let bOverN = b/n
				let dOverN = d/n
				
				func transformation(_ point:GlyphPoint)->GlyphPoint {
					return GlyphPoint(x: m * (aOverM * point.x + cOverM * point.y )
						,y: n * (bOverN * point.x + dOverN * point.y )
						,isOnCurve: point.isOnCurve)
				}
				
				let transformedComponentContours:[[GlyphPoint]] = componentContours.map({
					return $0.map(transformation)
				})
				
				let existingCoordinate:Point = point(in: allContours, at:indexOfMatchingPointInCompoundBeingConstructed)
				let componentCoordinate:Point = point(in: transformedComponentContours, at:indexOfMatchingPointInComponent)
				
				let dx:SGFloat = existingCoordinate.x - componentCoordinate.x
				let dy:SGFloat = existingCoordinate.y - componentCoordinate.y
				
				let translatedComponentContours:[[GlyphPoint]] = transformedComponentContours.map({ points in
					return points.map({ point in
						return GlyphPoint(x: point.x + dx, y: point.y + dy, isOnCurve: point.isOnCurve)
					})
				})
				allContours.append(contentsOf:translatedComponentContours)
			}
		} while flags.contains(.additionalGlyphsAfterThisOne)
		//TODO: instructions fill the rest of the range of the glyph
		return allContours
	}
	
}

struct Glyph {
	var boundingBox:GlyphBox
	var contours:[[GlyphPoint]]
}

struct GlyphBox {
	var xMin:SGFloat
	var yMin:SGFloat
	var xMax:SGFloat
	var yMax:SGFloat
}

struct GlyphPoint {
	var x:SGFloat
	var y:SGFloat
	var isOnCurve:Bool
}


struct GlyphFlags : OptionSet {
	var rawValue: UInt8
	
	init(rawValue: UInt8) {
		self.rawValue = rawValue
	}
	
	static let pointIsOnCurve:GlyphFlags = GlyphFlags(rawValue: 1<<0)
	static let xIsShort:GlyphFlags = GlyphFlags(rawValue: 1<<1)
	static let yIsShort:GlyphFlags = GlyphFlags(rawValue: 1<<2)
	static let repeats:GlyphFlags = GlyphFlags(rawValue: 1<<3)
	
	///if xIsShort is set, then this is the sign bit
	static let shortXSign:GlyphFlags = GlyphFlags(rawValue: 1<<4)
	///if yIsShort is set, then this is the sign bit
	static let shortYSign:GlyphFlags = GlyphFlags(rawValue: 1<<5)
	
	
	///if xIsShort is not set, this tells if the x coordinate is the same as the pervious
	static let xIsTheSame:GlyphFlags = GlyphFlags(rawValue: 1<<4)
	
	///if yIsShort is not set, this tells if the y coordinate is the same as the pervious
	static let yIsTheSame:GlyphFlags = GlyphFlags(rawValue: 1<<5)
	
}



struct CompoundGlyphFlags : OptionSet {
	var rawValue: UInt16
	
	init(rawValue: UInt16) {
		self.rawValue = rawValue
	}
	
	static let arg1And2AreWords:CompoundGlyphFlags = CompoundGlyphFlags(rawValue: 1<<0)
	static let argsAreXYValues:CompoundGlyphFlags = CompoundGlyphFlags(rawValue: 1<<1)
	static let roundXYToGrid:CompoundGlyphFlags = CompoundGlyphFlags(rawValue: 1<<2)
	static let transformationIncludesScale:CompoundGlyphFlags = CompoundGlyphFlags(rawValue: 1<<3)
	static let additionalGlyphsAfterThisOne:CompoundGlyphFlags = CompoundGlyphFlags(rawValue: 1<<5)
	static let differentXAndYScales:CompoundGlyphFlags = CompoundGlyphFlags(rawValue: 1<<6)
	static let twoByTwoTransformationMatrix:CompoundGlyphFlags = CompoundGlyphFlags(rawValue: 1<<7)
	static let includesInstructions:CompoundGlyphFlags = CompoundGlyphFlags(rawValue: 1<<8)
	static let useMetricsFromThisForCompoundGlyph:CompoundGlyphFlags = CompoundGlyphFlags(rawValue: 1<<9)
	static let overlap:CompoundGlyphFlags = CompoundGlyphFlags(rawValue: 1<<10)
	
}
