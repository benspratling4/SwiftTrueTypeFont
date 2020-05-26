//
//  File.swift
//  
//
//  Created by Ben Spratling on 5/24/20.
//

import Foundation

enum GlyphError : Error {
	case unsupportedFeature
}

struct GlyphTable {
	
	init(data:Data, in range:Range<Int>)throws {
		subData = Data(data[range])
	}
	
	var subData:Data
	
	///in f units
	func boundingBox(in range:Range<Int>)throws->GlyphBox {
		let start:Int = range.lowerBound
		let xMin:Int16 = try subData.readMSBFixedWidthInt(at: start + 2)
		let yMin:Int16 = try subData.readMSBFixedWidthInt(at: start + 4)
		let xMax:Int16 = try subData.readMSBFixedWidthInt(at: start + 6)
		let yMax:Int16 = try subData.readMSBFixedWidthInt(at: start + 8)
		return GlyphBox(xMin: xMin, yMin: yMin, xMax: xMax, yMax: yMax)
	}
	
	///nil means whitespace
	func glyph(in range:Range<Int>)throws->Glyph? {
		let start:Int = range.lowerBound
		let end:Int = range.upperBound
		if end == start {
			return nil
		}
		let numberOfCounters:Int16 = try subData.readMSBFixedWidthInt(at: start)
		let isCompound:Bool = numberOfCounters < 0
		let contourCount:Int = Int(numberOfCounters) * (isCompound ? -1 : 1)
		//in f units
		let xMin:Int16 = try subData.readMSBFixedWidthInt(at: start + 2)
		let yMin:Int16 = try subData.readMSBFixedWidthInt(at: start + 4)
		let xMax:Int16 = try subData.readMSBFixedWidthInt(at: start + 6)
		let yMax:Int16 = try subData.readMSBFixedWidthInt(at: start + 8)
		if isCompound {
			//TODO: write me
			//for compound glyphs, we need the loca table to find the sub-glyphs, indicating this algorithm should be at a higher level.
			throw GlyphError.unsupportedFeature
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
		var xCoords:[Int16] = []
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
			xCoords.append(newX + (xCoords.last ?? 0))
		}
		
		var yCoords:[Int16] = []
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
			yCoords.append(newY + (yCoords.last ?? 0))
		}
		
		//now transform flags x and y into contours and points
		var contours:[GlyphContour] = []
		var points:[GlyphPoint] = []
		for (pointIndex, flags) in pointFlags.enumerated() {
			points.append(GlyphPoint(x: xCoords[pointIndex], y: yCoords[pointIndex], isOnCurve: flags.contains(.pointIsOnCurve)))
			if pointIndex == indicesOfContourEndpoints[0] {
				_ = indicesOfContourEndpoints.removeFirst()
				contours.append(GlyphContour(points: points))
				points = []
			}
		}
		
		return Glyph(boundingBox: GlyphBox(xMin: xMin, yMin: yMin, xMax: xMax, yMax: yMax), format: .simple(SimpleGlyph(contours: contours)))
	}
	
}

struct GlyphBox {
	var xMin:Int16
	var yMin:Int16
	var xMax:Int16
	var yMax:Int16
}

struct Glyph {
	var boundingBox:GlyphBox
	
	var format:GlyphFormat
}

enum GlyphFormat {
	case simple(SimpleGlyph)
	case compound([SimpleGlyph])
}

struct SimpleGlyph {
	var contours:[GlyphContour]
}

struct GlyphContour {
	var points:[GlyphPoint]
}

struct GlyphPoint {
	var x:Int16
	var y:Int16
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
