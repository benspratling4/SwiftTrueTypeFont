//
//  HorizontalHeaderTable.swift
//  SwiftTrueTypeFont
//
//  Created by Ben Spratling on 4/29/20.
//

import Foundation


public enum HorizontalHeaderTableError : Error {
	case invalidFormat(UInt16)
}

public struct HorizontalHeaderTable {
	public var majorVersion:UInt16
	public var minorVersion:UInt16
	public var ascender:Int16
	public var decender:Int16
	public var lineGap:Int16
	public var advanceWidthMax:UInt16
	public var minLeftSideBearing:Int16
	public var minRightSideBearing:Int16
	public var xMaxExtent:Int16
	public var caretSlopeRise:Int16
	public var caretSlopeRun:Int16
	public var caretOffset:Int16
	//skip 8 bytes
//	var metricDataFormat
	public var numberOfHMetrics:UInt16
	
	init(data:Data, in range:Range<Int>)throws {
		let offset:Int = range.lowerBound
		majorVersion = try data.readMSBFixedWidthUInt(at: offset + 0)
		minorVersion = try data.readMSBFixedWidthUInt(at: offset + 2)
		ascender = try data.readMSBFixedWidthInt(at: offset + 4)
		decender = try data.readMSBFixedWidthInt(at: offset + 6)
		lineGap = try data.readMSBFixedWidthInt(at: offset + 8)
		advanceWidthMax = try data.readMSBFixedWidthUInt(at: offset + 10)
		minLeftSideBearing = try data.readMSBFixedWidthInt(at: offset + 12)
		minRightSideBearing = try data.readMSBFixedWidthInt(at: offset + 14)
		xMaxExtent = try data.readMSBFixedWidthInt(at: offset + 16)
		caretSlopeRise = try data.readMSBFixedWidthInt(at: offset + 18)
		caretSlopeRun = try data.readMSBFixedWidthInt(at: offset + 20)
		caretOffset = try data.readMSBFixedWidthInt(at: offset + 22)
		
		numberOfHMetrics = try data.readMSBFixedWidthUInt(at: offset + 34)
		
	}
}
