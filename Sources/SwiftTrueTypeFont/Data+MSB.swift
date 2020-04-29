//
//  Data+MSB.swift
//  SwiftTrueTypeFont
//
//  Created by Ben Spratling on 4/28/20.
//

import Foundation

//Standard conveniences for reading MSB from Data


extension Data {
	func readMSBFixedWidthUInt<Result>(at offset:Int)throws->Result where Result:FixedWidthInteger, Result:UnsignedInteger {
		let byteCount:Int = Result.bitWidth / 8
		guard count >= offset + byteCount else {
			throw MsbUin32Error.insufficientCount(offset)
		}
		var byte:UInt8 = 0
		var value:Result = 0
		for i in 0..<byteCount {
			byte = self[offset + i]
			value = value << 8
			value += Result(byte)
		}
		return value
	}
	
	init<Result>(MSBFixedWidthUInt:Result) where Result:FixedWidthInteger, Result:UnsignedInteger {
		var bytes:[UInt8] = []
		var lotsOfBytes:Result = MSBFixedWidthUInt
		for _ in 0..<4 {
			let aByte:Result = lotsOfBytes & Result(0xFF)
			let byte:UInt8 = UInt8(clamping: aByte)
			bytes.append(byte)
			lotsOfBytes = lotsOfBytes >> 8
		}
		self = Data(bytes)
	}
	
	init<Result>(LSBFixedWidthUInt:Result) where Result:FixedWidthInteger, Result:UnsignedInteger {
		var bytes:[UInt8] = []
		var lotsOfBytes:Result = LSBFixedWidthUInt
		for _ in 0..<4 {
			let aByte:Result = lotsOfBytes & Result(0xFF)
			let byte:UInt8 = UInt8(clamping: aByte)
			bytes.insert(byte, at: 0)
			lotsOfBytes = lotsOfBytes >> 8
		}
		self = Data(bytes)
	}
	
	
}


extension Data {
	func readMsbUInt32(at offset:Int)throws->UInt32 {
		return try readMSBFixedWidthUInt(at:offset)
	}
}


extension Data {
	init(long32:UInt32) {
		var bytes:[UInt8] = []
		var lotsOfBytes:UInt32 = long32
		for _ in 0..<4 {
			let aByte:UInt32 = lotsOfBytes & 0x000000FF
			let byte:UInt8 = UInt8(clamping: aByte)
			bytes.append(byte)
			lotsOfBytes = lotsOfBytes >> 8
		}
		self = Data(bytes)
	}
}


enum MsbUin32Error : Error {
	case insufficientCount(Int)	//Int is offset
}
