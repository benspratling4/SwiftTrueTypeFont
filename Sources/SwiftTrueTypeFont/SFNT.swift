//
//  SFNT.swift
//  
//
//  Created by Ben Spratling on 5/25/20.
//

import Foundation

public enum SFNTError : Error {
	case tableDoesntExist, invalidTableRecord, invalidTableName
}


//Metaformat used by TTF, OTF, etc...
class SFNT {
	
	init(data:Data) throws {
		self.data = data
		let numberOfTables:Int = try OffsetTable(data: data).numberOfTables
		tableRecords = try (0..<numberOfTables).map({try TableRecord(data: data, at:12 + $0 * 16)})
	}
	
	let data:Data
	//all ints are MSB
	
	let tableRecords:[TableRecord]
	
	var tableTags:[UInt32] {
		return tableRecords.map({$0.tag})
	}
	
	var tableTagStrings:[String] {
		return tableRecords.map { $0.tagName }
	}
	
	///returns nil if the table doesn't exist, throws
	func tableRange(tag:UInt32)throws->Range<Int> {
		guard let record = tableRecords.first(where: {$0.tag == tag}) else { throw SFNTError.tableDoesntExist }
		let endByte:Int = record.offset + record.count
		guard data.count >= endByte else { throw SFNTError.invalidTableRecord }
		return record.offset..<record.offset+record.count
	}
	
	func tableRange(tag:String)throws->Range<Int> {
		guard let chars:Data = tag.data(using: .utf8) else {
			throw SFNTError.invalidTableName
		}
		let tag:UInt32 = try chars.readMsbUInt32(at: 0)
		return try tableRange(tag: tag)
	}
}
