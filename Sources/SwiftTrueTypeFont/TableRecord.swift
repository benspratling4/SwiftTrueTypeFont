//
//  TableRecord.swift
//  SwiftTrueTypeFont
//
//  Created by Benjamin Spratling on 11/1/19.
//

import Foundation

///a standard record of where are the tables in the file, and how big are they
struct TableRecord {
	var tag:UInt32
//	var checksum:UInt32
	var offset:Int	//stored as UInt32
	var count:Int	// stored as UInt32
	
	
	var tagName:String {
		return String(data:Data(MSBFixedWidthUInt: tag), encoding: .ascii) ?? ""
	}
	
	init(data:Data, at offset:Int)throws {
		tag = try data.readMsbUInt32(at:offset)
		self.offset = Int(try data.readMsbUInt32(at: offset + 8))
		self.count = Int(try data.readMsbUInt32(at: offset + 12))
	}
	
}


public enum TableRecordError : Error {
	case fileShorterThanTableRecord
}

