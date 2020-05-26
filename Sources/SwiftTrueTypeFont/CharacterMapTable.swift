 //
//  CharacterMapTable.swift
//  SwiftTrueTypeFont
//
//  Created by Ben Spratling on 4/29/20.
//

import Foundation

public enum CharacterMapTableError : Error {
	case unsupportedFormat(UInt16)
}


struct CharacterMapTable {
	var version:UInt16
	var numTables:uint16
	var encodingRecords:[EncodingRecord]
	var tables:[CharacterEncodingTable]
	
	init(data:Data, in range:Range<Int>)throws {
		let offset:Int = range.lowerBound
		version = try data.readMSBFixedWidthUInt(at: offset + 0)
		numTables = try data.readMSBFixedWidthUInt(at: offset + 2)
		encodingRecords = (0..<Int(numTables)).compactMap({ index in
			return try? EncodingRecord(data: data, at:offset + 4 + 8 * index)
		})
		tables = encodingRecords.compactMap({ try? CharacterMapTable.newCharacterEncodingTable(data: data, offset: offset + Int($0.offset), encodingRecord: $0) })
	}
	
}


struct EncodingRecord {
	var platformId:NameRecord.PlatformId
	var encodingID:UInt16
	var offset:UInt32
	
	init(data:Data, at offset:Int)throws {
		let platformShort:UInt16 = try data.readMSBFixedWidthUInt(at: offset)
		platformId = NameRecord.PlatformId(rawValue: platformShort) ?? .custom
		encodingID = try data.readMSBFixedWidthUInt(at: offset + 2)
		self.offset = try data.readMSBFixedWidthUInt(at: offset + 4)
	}
}


protocol CharacterEncodingTable {
	var encodingRecord:EncodingRecord { get }
	func glyphIndex(characterIndex:Int)->Int
}

extension CharacterMapTable {
	
	static func newCharacterEncodingTable(data:Data, offset:Int, encodingRecord:EncodingRecord)throws->CharacterEncodingTable? {
		let format:UInt16 = try data.readMSBFixedWidthUInt(at: offset + 0)
		switch format {
		case 0:
			return try CharacterEncodingTableFormat0(data: data, at: offset + 2, encodingRecord:encodingRecord)
//		case 2:
//			return try CharacterEncodingTableFormat2(data: data, at: offset + 2, encodingRecord:encodingRecord)
			
		case 4:
			return try CharacterEncodingTableFormat4(data: data, at: offset + 2, encodingRecord: encodingRecord)
			
		default:
			throw CharacterMapTableError.unsupportedFormat(format)
		}
	}
	
	struct CharacterEncodingTableFormat0 : CharacterEncodingTable {
//		var format:UInt16	//0
		var encodingRecord:EncodingRecord
		var length:UInt16
		var language:UInt16
		var glyphIdArray:[UInt8]
		
		init(data:Data, at offset:Int, encodingRecord:EncodingRecord)throws {
			self.encodingRecord = encodingRecord
			length = try data.readMSBFixedWidthUInt(at: offset + 0)
			language = try data.readMSBFixedWidthUInt(at: offset + 2)
			glyphIdArray = [UInt8](repeating: 0, count:CharacterEncodingTableFormat0.glyphArrayLength)
			data.copyBytes(to: &glyphIdArray, from: offset+4..<offset+4+CharacterEncodingTableFormat0.glyphArrayLength)
		}
		
		static let glyphArrayLength:Int = 256
		
		func glyphIndex(characterIndex:Int)->Int {
			guard characterIndex < glyphIdArray.count else { return .missingCharacterGlyphIndex }
			return Int(glyphIdArray[characterIndex])
		}
	}
	/*
	struct CharacterEncodingTableFormat2 : CharacterEncodingTable {
//		var format:UInt16	//2
		var encodingRecord:EncodingRecord
		var length:UInt16
		var language:UInt16
		var subHeaderKeys:[UInt16]
		var subHeaders:[SubHeader]
		var glyphIndexArray:[UInt16]
		
		init(data:Data, at offset:Int, encodingRecord:EncodingRecord)throws {
			self.encodingRecord = encodingRecord
			length = try data.readMSBFixedWidthUInt(at: offset + 0)
			language = try data.readMSBFixedWidthUInt(at: offset + 2)
			let subHeaderKeyRange:Range<Int> = offset+4..<offset+4+CharacterEncodingTableFormat2.glyphArrayLength
			subHeaderKeys = [UInt16](repeating: 0, count:CharacterEncodingTableFormat2.glyphArrayLength)
			_ = subHeaderKeys.withUnsafeMutableBytes {
				data.copyBytes(to: $0, from: subHeaderKeyRange)
			}
			subHeaderKeys = subHeaderKeys.map({ UInt16(bigEndian: $0) })
			//TODO: write me
		}
		
		static let glyphArrayLength:Int = 256
		
		
		func glyphIndex(characterIndex:Int)->Int? {
			//TODO: write me
		}
		
		
		struct SubHeader {
			var firstCode:UInt16
			var entryCount:UInt16
			var idDelta:Int16
			var idRangeOffset:UInt16
			
			init(data:Data, at offset:Int) {
				
				
				
				//TODO: write me
			}
		}
		
		
	}
	*/
	
	
	struct CharacterEncodingTableFormat4 : CharacterEncodingTable {
	//	var format:UInt16	//4
		var encodingRecord:EncodingRecord
		var length:UInt16
		var language:UInt16
		var segmentCount:Int
		var endCodes:[UInt16]
		var startCodes:[UInt16]
		var idDeltas:[UInt16]
		var idRangeOffsets:[UInt16]
		var glyphIndexArray:[UInt16]
		
		init(data:Data, at offset:Int, encodingRecord:EncodingRecord)throws {
			self.encodingRecord = encodingRecord
			length = try data.readMSBFixedWidthUInt(at: offset + 0)
			language = try data.readMSBFixedWidthUInt(at: offset + 2)
			let segCountX2:UInt16 = try data.readMSBFixedWidthUInt(at: offset + 4)
			let segmentCount = Int(segCountX2)/2
			self.segmentCount = segmentCount
			let endCodesStart:Int = offset+12
			let endCodes:[UInt16] = try data.readMSBFixedWidthArray(at: endCodesStart, count: segmentCount)
			self.endCodes = endCodes
			let startCodeStart:Int = endCodesStart + 2*segmentCount + 2
			let startCodes:[UInt16] = try data.readMSBFixedWidthArray(at: startCodeStart, count: segmentCount)
			self.startCodes = startCodes
			let idDeltaStart:Int = startCodeStart + 2*segmentCount
			idDeltas = try data.readMSBFixedWidthArray(at: idDeltaStart, count: segmentCount)
			let idRangeOffsetStart:Int = idDeltaStart + 2*segmentCount
			idRangeOffsets = try data.readMSBFixedWidthArray(at: idRangeOffsetStart, count: segmentCount)
			let glyphIndexArrayStart:Int = idRangeOffsetStart + 2*segmentCount
			let nonZeroIdRangeOffsets:[(Int, UInt16)] = idRangeOffsets.enumerated().filter { $1 != 0}
			
			//what's the furthest address into the glyph index array?  we need
			let allOffsets:[UInt16] = nonZeroIdRangeOffsets.map {
				//TODO: fix me, make this math modulo 65536
				let maxCodeDiff:UInt16 = endCodes[$0.0] - startCodes[$0.0]
				let less = UInt16(segmentCount - $0.0)
				return maxCodeDiff &+ $0.1/2 &- less &+ 2
			}
			let glyphIndexLength:Int =  Int( allOffsets.reduce(0, max) )
			glyphIndexArray = try data.readMSBFixedWidthArray(at: glyphIndexArrayStart, count: glyphIndexLength)
		}
		
		
		func glyphIndex(characterIndex: Int) -> Int {
			guard let segmentIndex:Int = endCodes.firstIndex(where: { Int($0) >= characterIndex }) else {
				return .missingCharacterGlyphIndex
			}
			let startIndex:Int = Int(startCodes[segmentIndex])
			guard startIndex <= characterIndex else { return .missingCharacterGlyphIndex }
			let idRangeOffset:UInt16 = idRangeOffsets[segmentIndex]
			if idRangeOffset == 0 {
				//All idDelta[i] arithmetic is modulo 65536.
				if characterIndex > Int(UInt16.max) { return .missingCharacterGlyphIndex }
				let shortCharIndex = UInt16(characterIndex)
				let finalIndex:UInt16 = shortCharIndex &+ idDeltas[segmentIndex]
				return Int(finalIndex)
			} else {
				let offset:Int = characterIndex - startIndex
				let less:UInt16 = UInt16(idRangeOffsets.count) - UInt16(segmentIndex)
				let indexInto:UInt16 = UInt16(offset) &+ idRangeOffset/UInt16(2) &- less
				let glyphIndex:Int = Int(glyphIndexArray[Int(indexInto)])
				if glyphIndex == 0 {
					return .missingCharacterGlyphIndex
				}
				let shortGlyphIndex = UInt16(characterIndex)
				let finalIndex:UInt16 = shortGlyphIndex &+ idDeltas[segmentIndex]
				return Int(finalIndex)
			}
		}
		
	}
	
	
}



extension Int {
	public static let missingCharacterGlyphIndex = 0
}
