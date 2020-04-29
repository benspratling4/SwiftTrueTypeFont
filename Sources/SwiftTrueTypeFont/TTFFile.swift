//
//  TTFFile.swift
//  SwiftTrueTypeFont
//
//  Created by Benjamin Spratling on 11/1/19.
//

import Foundation


public enum TTFError : Error {
	case invalidTableRecord
	case tableDoesntExist
	
	///i.e.the table name you gave wasn't
	case invalidTableName
}

/// based on the OpenType font spec https://docs.microsoft.com/en-us/typography/opentype/spec/otff
public class TTF {
	
	public init(data:Data) throws {
		self.data = data
		let numberOfTables:Int = try OffsetTable(data: data).numberOfTables
		tableRecords = try (0..<numberOfTables).map({try TableRecord(data: data, at:12 + $0 * 16)})
	}
	
	let data:Data
	//all ints are MSB
	
	let tableRecords:[TableRecord]
	
	public var tableTags:[UInt32] {
		return tableRecords.map({$0.tag})
	}
	
	public var tableTagStrings:[String] {
		return tableRecords.map { $0.tagName }
	}
	
	///returns nil if the table doesn't exist, throws
	public func tableData(with tag:UInt32)throws->(Data, Int) {
		guard let record = tableRecords.first(where: {$0.tag == tag}) else { throw TTFError.tableDoesntExist }
		let endByte:Int = record.offset + record.count
		guard data.count >= endByte else { throw TTFError.invalidTableRecord }
		return (data, record.offset)
	}
	
	public func tableData(with tag:String)throws->(Data, Int) {
		guard let chars:Data = tag.data(using: .utf8) else {
			throw TTFError.invalidTableName
		}
		let tag:UInt32 = try chars.readMsbUInt32(at: 0)
		return try tableData(with: tag)
	}
	
	
	public var nameTable:NameTable? {
		guard let (data, nameTableStart) = try? tableData(with:"name") else { return nil }
		return try? NameTable(data: data, at: nameTableStart)
	}
}
