//
//  OffsetTable.swift
//  SwiftTrueTypeFont
//
//  Created by Benjamin Spratling on 11/1/19.
//

import Foundation


public enum OffsetTableError : Error {
	case fileShorterThanRequiredOffsetTableValues
}


struct OffsetTable {
	//fields in order of their values
//	var sfntVersion:UInt32
	var numberOfTables:Int	//stored as a UInt16
//	var searchRange:UInt16
//	var entrySelector:UInt16
//	var rangeShift:UInt16
	
	init(data:Data)throws {
		if data.count < 12 {
			throw OffsetTableError.fileShorterThanRequiredOffsetTableValues
		}
		let tableCount:UInt16 = try data.readMSBFixedWidthUInt(at: 4)
		self.numberOfTables = Int(tableCount)
	}
	
}
