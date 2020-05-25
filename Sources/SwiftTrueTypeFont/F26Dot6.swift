//
//  File.swift
//  
//
//  Created by Ben Spratling on 5/23/20.
//

import Foundation

struct F26Dot6 : Comparable, CustomStringConvertible {
	//26 bits integer
	//6 bits fractional
	//signed int, so we get arithmetic bit shifting
	fileprivate var value:Int32
	
	init(bitPattern:Int32) {
		self.value = bitPattern
	}
	
	var bitPattern:Int32 {
		return value
	}
	
	init(clamping value:Int) {
		self.value = Int32(clamping:value) << 6
	}
	
	init(approximate value:Float64) {
		self.value = Int32((value * 64))
	}
	
	/// truncates fractional bits
	var intValue:Int32 {
		return value >> 6
	}
	
	var floatValue:Float64 {
		return Float64(value)/64
	}
	
	static func +(lhs:F26Dot6, rhs:F26Dot6)->F26Dot6 {
		return F26Dot6(bitPattern:lhs.value + rhs.value)
	}
	
	static prefix func -(lhs:F26Dot6)->F26Dot6 {
		return F26Dot6(bitPattern:-lhs.value)
	}
	
	static func -(lhs:F26Dot6, rhs:F26Dot6)->F26Dot6 {
		return F26Dot6(bitPattern:lhs.value - rhs.value)
	}
	
	static func *(lhs:F26Dot6, rhs:F26Dot6)->F26Dot6 {
		let widerl:Int64 = Int64(lhs.value)
		let widerr:Int64 = Int64(rhs.value)
		let product:Int64 = widerl * widerr
		let shifted:Int64 = product >> 6
		let final:Int32 = Int32(clamping: shifted)
		return F26Dot6(bitPattern: final)
	}
	
	static func /(lhs:F26Dot6, rhs:F26Dot6)->F26Dot6 {
		let widerl:Int64 = Int64(lhs.value) << 6
		let widerr:Int64 = Int64(rhs.value)
		let dividend:Int64 = widerl / widerr
		let final:Int32 = Int32(clamping: dividend)
		return F26Dot6(bitPattern: final)
	}
	
	
	//MARK: - CustomStringConvertible
	
	var description:String {
		return floatValue.description
	}
	
	
	//MARK: - Comparable
	
	static func <(lhs:F26Dot6, rhs:F26Dot6)->Bool {
		return lhs.value < rhs.value
	}
	
	
	//MARK: - Equatable
	
	static func ==(lhs:F26Dot6, rhs:F26Dot6)->Bool {
		return lhs.value == rhs.value
	}
	
}

func abs(_ fixed:F26Dot6)->F26Dot6 {
	return F26Dot6(bitPattern:abs(fixed.value))
}

func ceil(_ fixed:F26Dot6)->F26Dot6 {
	//TODO: how do I do this for negative numbers?
	fatalError("write me")
}



