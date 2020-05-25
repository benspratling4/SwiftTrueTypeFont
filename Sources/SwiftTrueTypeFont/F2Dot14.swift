//
//  File.swift
//  
//
//  Created by Ben Spratling on 5/24/20.
//

import Foundation

struct F2Dot14 : Comparable, CustomStringConvertible {
	//2 bits integer
	//14 bits fractional
	//signed int, so we get arithmetic bit shifting
	fileprivate var value:Int16
	
	init(bitPattern:Int16) {
		self.value = bitPattern
	}
	
	var bitPattern:Int16 {
		return value
	}
	
	init(clamping value:Int) {
		self.value = Int16(clamping:value) << 14
	}
	
	init(approximate value:Float64) {
		self.value = Int16((value * 16384))
	}
	
	/// truncates fractional bits
	var intValue:Int16 {
		return value >> 14
	}
	
	var floatValue:Float64 {
		return Float64(value)/16384
	}
	
	static func +(lhs:F2Dot14, rhs:F2Dot14)->F2Dot14 {
		return F2Dot14(bitPattern:lhs.value + rhs.value)
	}
	
	static prefix func -(lhs:F2Dot14)->F2Dot14 {
		return F2Dot14(bitPattern:-lhs.value)
	}
	
	static func -(lhs:F2Dot14, rhs:F2Dot14)->F2Dot14 {
		return F2Dot14(bitPattern:lhs.value - rhs.value)
	}
	
	static func *(lhs:F2Dot14, rhs:F2Dot14)->F2Dot14 {
		let widerl:Int32 = Int32(lhs.value)
		let widerr:Int32 = Int32(rhs.value)
		let product:Int32 = widerl * widerr
		let shifted:Int32 = product >> 14
		let final:Int16 = Int16(clamping: shifted)
		return F2Dot14(bitPattern: final)
	}
	
	static func /(lhs:F2Dot14, rhs:F2Dot14)->F2Dot14 {
		let widerl:Int32 = Int32(lhs.value) << 14
		let widerr:Int32 = Int32(rhs.value)
		let dividend:Int32 = widerl / widerr
		let final:Int16 = Int16(clamping: dividend)
		return F2Dot14(bitPattern: final)
	}
	
	
	//MARK: - CustomStringConvertible
	
	var description:String {
		return floatValue.description
	}
	
	
	//MARK: - Comparable
	
	static func <(lhs:F2Dot14, rhs:F2Dot14)->Bool {
		return lhs.value < rhs.value
	}
	
	
	//MARK: - Equatable
	
	static func ==(lhs:F2Dot14, rhs:F2Dot14)->Bool {
		return lhs.value == rhs.value
	}
	
	
	static let one:F2Dot14 = F2Dot14(clamping: 1)
	static let zero:F2Dot14 = F2Dot14(clamping: 0)
}

func abs(_ fixed:F2Dot14)->F2Dot14 {
	return F2Dot14(bitPattern:abs(fixed.value))
}

func ceil(_ fixed:F2Dot14)->F2Dot14 {
	//TODO: how do I do this for negative numbers?
	fatalError("write me")
}

struct Point2Dot14 {
	var x:F2Dot14
	var y:F2Dot14
}

