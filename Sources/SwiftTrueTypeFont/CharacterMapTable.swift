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
//		var glyphIndexArray:[UInt16]	//we don't know how long it is
		
		init(data:Data, at offset:Int, encodingRecord:EncodingRecord)throws {
			self.encodingRecord = encodingRecord
			length = try data.readMSBFixedWidthUInt(at: offset + 0)
			language = try data.readMSBFixedWidthUInt(at: offset + 2)
			let segCountX2:UInt16 = try data.readMSBFixedWidthUInt(at: offset + 4)
			segmentCount = Int(segCountX2)/2
			let endCodesStart:Int = offset+12
			endCodes = try data.readMSBFixedWidthArray(at: endCodesStart, count: segmentCount)
			let startCodeStart:Int = endCodesStart + 2*segmentCount + 2
			startCodes = try data.readMSBFixedWidthArray(at: startCodeStart, count: segmentCount)
			let idDeltaStart:Int = startCodeStart + 2*segmentCount
			idDeltas = try data.readMSBFixedWidthArray(at: idDeltaStart, count: segmentCount)
			let idRangeOffsetStart:Int = idDeltaStart + 2*segmentCount
			idRangeOffsets = try data.readMSBFixedWidthArray(at: idRangeOffsetStart, count: segmentCount)
			//TODO: figure out how long this array is
//			glyphIndexArray = try data.readMSBFixedWidthArray(at: idRangeOffsetStart, count: segmentCount)
//			fatalError("write me")
		}
		
		
		func glyphIndex(characterIndex: Int) -> Int {
			guard let segmentIndex:Int = endCodes.firstIndex(where: { Int($0) >= characterIndex }) else {
				return .missingCharacterGlyphIndex
			}
			let startIndex:Int = Int(startCodes[segmentIndex])
			guard startIndex <= characterIndex else { return .missingCharacterGlyphIndex }
			let idRangeOffset:Int = Int(idRangeOffsets[segmentIndex])
			if idRangeOffset == 0 {
				//All idDelta[i] arithmetic is modulo 65536.
				if characterIndex > Int(UInt16.max) { return .missingCharacterGlyphIndex }
				let shortCharIndex = UInt16(characterIndex)
				let finalIndex:UInt16 = shortCharIndex &+ idDeltas[segmentIndex]
				return Int(finalIndex)
			} else {
				let offset:Int = characterIndex - startIndex
				idRangeOffset + offset
				//TODO: write me
				fatalError("write me")
			}
		}
		
	}
	
	
}



extension Int {
	public static let missingCharacterGlyphIndex = 0
}
