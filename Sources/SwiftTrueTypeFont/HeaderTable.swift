//
//  HeaderTable.swift
//  SwiftTrueTypeFontTests
//
//  Created by Ben Spratling on 4/28/20.
//

import Foundation

public enum HeaderTableError : Error {
	case invalidFormat(UInt16)
}

public struct HeaderTable {
	public var version:UInt32
//	var fontRevision: 32 bits
//	var checkSumAdjustment: 32 bits
//	let magicNumber: 32 bits
	public var flags:HeaderFlags	//16 bits
	public var unitsPerEm:UInt16
//	var created 64 bits
//	var modified 64 bits
	public var xMin:Int16
	public var yMin:Int16
	public var xMax:Int16
	public var yMax:Int16
//	var macStyle: 16 bits
	public var lowestRecPPEM:UInt16
//	var fontDirectionHint: 16 bits	//deprecated
	public var indexToLocFormat:Int16
	public var glyphDataFormat:Int16
	
	init(data:Data, in range:Range<Int>)throws {
		let offset:Int = range.lowerBound
		version = try data.readMSBFixedWidthUInt(at: offset + 0)
		flags = HeaderFlags(rawValue: try data.readMSBFixedWidthUInt(at: offset + 16))
		unitsPerEm = try data.readMSBFixedWidthUInt(at: offset + 18)
		xMin = try data.readMSBFixedWidthInt(at: offset + 36)
		yMin = try data.readMSBFixedWidthInt(at: offset + 38)
		xMax = try data.readMSBFixedWidthInt(at: offset + 40)
		yMax = try data.readMSBFixedWidthInt(at: offset + 42)
		lowestRecPPEM = try data.readMSBFixedWidthUInt(at: offset + 46)
		indexToLocFormat = try data.readMSBFixedWidthInt(at: offset + 48)
		glyphDataFormat = try data.readMSBFixedWidthInt(at: offset + 50)
	}
	
	
	public struct HeaderFlags: OptionSet {
		public let rawValue: UInt16
		
		public init(rawValue: UInt16) {
			self.rawValue = rawValue
		}
		
		public static let y0Baseline = HeaderFlags(rawValue: 1 << 0)
		public static let leftSidebearingPointAtX0 = HeaderFlags(rawValue: 1 << 1)
		public static let instructionsDependOnPointSize = HeaderFlags(rawValue: 1 << 2)
		public static let forcePpemToIntegerValues = HeaderFlags(rawValue: 1 << 3)
		public static let instructionsAlterAdvanceWidth = HeaderFlags(rawValue: 1 << 4)
		//bit 5 not set in OpenType, may be used for Apple ttf
		//bits 6-10 never set
		
		///if set, DSIG table may be invalid
		public static let losslessCompression = HeaderFlags(rawValue: 1 << 11)
		public static let converted = HeaderFlags(rawValue: 1 << 12)
		public static let optimizedForClearType = HeaderFlags(rawValue: 1 << 13)
		public static let lastResortFont = HeaderFlags(rawValue: 1 << 14)
		//bit 15 reserved
	}
	
	
	
	
}
