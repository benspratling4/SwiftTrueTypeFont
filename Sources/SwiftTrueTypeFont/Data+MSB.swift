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
		let placeHolder:Result = withUnsafeBytes { pointer in
			return pointer.load(fromByteOffset: offset, as: Result.self)
		}
		return Result(bigEndian: placeHolder)
	}
	
	
	func readMSBFixedWidthInt<Result>(at offset:Int)throws->Result where Result:FixedWidthInteger, Result:SignedInteger {
		let byteCount:Int = Result.bitWidth / 8
		guard count >= offset + byteCount else {
			throw MsbUin32Error.insufficientCount(offset)
		}
		let placeHolder:Result = withUnsafeBytes { pointer in
			return pointer.load(fromByteOffset: offset, as: Result.self)
		}
		return Result(bigEndian: placeHolder)
	}
	
	func readMSBFixedWidthArray<Result>(at offset:Int, count:Int)throws->[Result] where Result:FixedWidthInteger/*, Result:SignedInteger*/ {
		let range:Range<Int> = offset..<offset+count*MemoryLayout<Result>.size
		var values:[Result] = [Result](repeating: 0, count:count)
		_ = values.withUnsafeMutableBytes {
			copyBytes(to: $0, from: range)
		}
		return values.map({ Result(bigEndian: $0) })
	}
	
	
	
	init<Result>(MSBFixedWidthUInt:Result) where Result:FixedWidthInteger, Result:UnsignedInteger {
		let byteCount:Int = Result.bitWidth / 8
		let bigValue:Result = MSBFixedWidthUInt.bigEndian
		self.init(count: byteCount)
		withUnsafeMutableBytes { pointer in
			pointer.bindMemory(to:Result.self).baseAddress?.pointee = bigValue
		}
	}
	
	init<Result>(LSBFixedWidthUInt:Result) where Result:FixedWidthInteger, Result:UnsignedInteger {
		let byteCount:Int = Result.bitWidth / 8
		let littleValue:Result = LSBFixedWidthUInt.littleEndian
		self.init(count: byteCount)
		withUnsafeMutableBytes { pointer in
			pointer.bindMemory(to:Result.self).baseAddress?.pointee = littleValue
		}
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
