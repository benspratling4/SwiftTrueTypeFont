//
//  File.swift
//  
//
//  Created by Ben Spratling on 5/25/20.
//

import Foundation


public enum MaxTableError : Error {
	
	
	
}


public struct MaxTable {
	public var version:UInt32
	public var numberOfGlyphs:Int
	
	init(data:Data, in range:Range<Int>)throws {
		let offset:Int = range.lowerBound
		version = try data.readMSBFixedWidthUInt(at: 0)
		let numGlyphs:UInt16 = try data.readMSBFixedWidthUInt(at: offset + 4)
		numberOfGlyphs = Int(numGlyphs)
		
		//other values aren't necessarily necessary
		
	}
	
}
