//
//  HorizontalMetricsTable.swift
//  
//
//  Created by Ben Spratling on 5/25/20.
//

import Foundation


public enum HorizontalMetricsTableError : Error {
	
}


struct HorizontalMetricsTable {
	
	///in f units
	var advancedWidthsAndLeftSideBearings:[(advanceWidth:UInt16, leftSideBearing:Int16)]
	
	init(data:Data, in range:Range<Int>, numberOfHMetrics:Int, numGlyphs:Int)throws {
		var dataIndex:Int = range.lowerBound
		advancedWidthsAndLeftSideBearings = []
		for _ in 0..<numberOfHMetrics {
			let advanceWidth:UInt16 = try data.readMSBFixedWidthUInt(at: dataIndex)
			dataIndex += 2
			let lsb:Int16 = try data.readMSBFixedWidthInt(at: dataIndex)
			dataIndex += 2
			advancedWidthsAndLeftSideBearings.append((advanceWidth, lsb))
		}
		
		for _ in 0..<numGlyphs-numberOfHMetrics {
			let lsb:Int16 = try data.readMSBFixedWidthInt(at: dataIndex)
			dataIndex += 2
			advancedWidthsAndLeftSideBearings.append((advancedWidthsAndLeftSideBearings.last!.advanceWidth, lsb))
		}
	}
}
