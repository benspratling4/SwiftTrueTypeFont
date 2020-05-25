//
//  File.swift
//  
//
//  Created by Ben Spratling on 5/24/20.
//

import Foundation

public enum LocationTableError : Error {
	case invalidFormat
	case glyphIndexOutOfBounds
}


///'loca'
struct LocationTable {
	
	var glyphOffsets:[Int]
	
	func rangeOfGlyph(at index:Int)throws->Range<Int> {
		guard index < glyphOffsets.count - 1 else { throw LocationTableError.glyphIndexOutOfBounds }
		return glyphOffsets[index]..<glyphOffsets[index+1]
	}
	
	///numGlyphs from maxp table
	///indexToLocFormat is from HeaderTable, 0 for short offsets, 1 for long
	init(data:Data, in range:Range<Int>, numGlyphs:Int, indexToLocFormat:Int16)throws {
		let offset:Int = range.lowerBound
		glyphOffsets = [Int](repeating: 0, count: numGlyphs+1)
		switch indexToLocFormat {
		case 0:	//short format
			//short offsets
			for i in 0..<numGlyphs+1 {
				let value:UInt16 = try data.readMSBFixedWidthUInt(at: offset + 2*i)
 				glyphOffsets[i] = 2 * Int(value)
			}
			
		case 1, 2:	//long offsets
			for i in 0..<numGlyphs+1 {
				let value:UInt32 = try data.readMSBFixedWidthUInt(at: offset + 4*i)
 				glyphOffsets[i] = Int(value)
			}
			
		default:
			//invalid format
			throw LocationTableError.invalidFormat
		}
	}
	
}
