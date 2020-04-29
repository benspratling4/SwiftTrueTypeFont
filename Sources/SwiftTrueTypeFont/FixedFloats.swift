//
//  FixedFloats.swift
//  SwiftTrueTypeFontTests
//
//  Created by Ben Spratling on 4/29/20.
//

import Foundation

public struct Fixed32 {
	public var integer:Int16
	public var fractional:UInt16
	//no math operations are provided at this time, because you are expected to convert to a FloatingPoint type for math
}

extension FloatingPoint {
	public init(_ value:Fixed32) {
		self = Self(value.integer) + Self(value.fractional)/Self(UInt16.max)
	}
}
