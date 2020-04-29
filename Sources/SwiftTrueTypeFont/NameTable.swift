//
//  NameTable.swift
//  SwiftTrueTypeFont
//
//  Created by Benjamin Spratling on 11/1/19.
//

import Foundation

public enum NameTableError : Error {
	case invalidFormat(UInt16)
}


public enum NameTable {
	case format0(NameTableFormat0)
	case format1(NameTableFormat1)
	
	
	init(data:Data, at offset:Int)throws {
		let format:UInt16 = try data.readMSBFixedWidthUInt(at: offset)
		switch format {
		case 0:
			self = .format0(try NameTableFormat0(data: data, at: offset))
			
		case 1:
			self = .format1(try NameTableFormat1(data: data, at: offset))
			
		default:
			throw NameTableError.invalidFormat(format)
		}
	}
	
	public var englishPostScriptName:String? {
		switch self {
		case .format1(_):
			return nil
			
		case .format0(let format0):
			return format0.nameRecords
				.filter({ $0.0.nameId == .postScriptName})
				.filter({ $0.0.languageId == NameRecord.englishLanguageIdFormat0(platformId: $0.0.platformId) })
				.first?.1
		}
	}
}


public struct NameTableFormat0 {
	let nameRecordCount:Int
	
	public var nameRecords:[(NameRecord, String)] = []
	init(data:Data, at offset:Int)throws {
		let nameRecord16:UInt16 = try data.readMSBFixedWidthUInt(at: offset + 2)
		self.nameRecordCount = Int(nameRecord16)
		let stringsOffset:UInt16 = try data.readMSBFixedWidthUInt(at: offset + 4)
		
		for i in 0..<nameRecordCount {
			let nameRecordOffset = offset + 6 + (i * 12)
			let record = try NameRecord(data: data, at: nameRecordOffset)
			let stringStart:Int = offset + Int(stringsOffset) + record.offset
			let stringDataEnd:Int = stringStart + record.length
			guard stringDataEnd <= data.count else { continue }
			let subData = data[stringStart..<(stringStart + record.length) ]
			guard let encoding = NameTableFormat0.stringEncoding(platformId: record.platformId, encodingId: record.encodingId) else {
				//try something
				
				continue }
			guard let value = String(data:subData, encoding: encoding) else { continue }	//FIXME: not all strings are utf8 encoded
			nameRecords.append( (record, value) )
		}
		//TODO: write me
	}
	
	static func stringEncoding(platformId:NameRecord.PlatformId, encodingId:UInt16)->String.Encoding? {
		switch platformId {
		case .unicode:
			switch encodingId {
			case 0, 1, 2:
				return .unicode	//the docs are kind of ambiguous about this
				
			default:
				return nil
			}
			
		case .macintosh:
			switch encodingId {
			case 0:
				return .macOSRoman
			case 1:
				return .japaneseEUC
			default:
				return nil
			}
			
		case .windows:
			switch encodingId {
			case 0, 1:
				return .utf16BigEndian
			case 2:
				return .shiftJIS
			default:
				return nil
			}
			
		case .iso:
			switch encodingId {
			case 0:
				return .ascii
			case 1:
				return .unicode
			case 2:
				return .isoLatin1
			default:
				return nil
			}
			
		default:
			return nil
		}
	}
	
}


public struct NameTableFormat1 {
	init(data:Data, at offset:Int)throws {
		
		//TODO: write me
	}
}


public struct NameRecord {
	public let platformId:PlatformId
	public let encodingId:UInt16
	public let languageId:UInt16
	public let nameId:NameId?
	let length:Int
	let offset:Int
	init(data:Data, at offset:Int)throws {
		let platformShort:UInt16 = try data.readMSBFixedWidthUInt(at: offset)
		platformId = PlatformId(rawValue: platformShort) ?? .custom
		encodingId = try data.readMSBFixedWidthUInt(at: offset + 2)
		languageId = try data.readMSBFixedWidthUInt(at: offset + 4)
		let nameShort:UInt16 = try data.readMSBFixedWidthUInt(at: offset + 6)
		self.nameId = NameId(rawValue: nameShort)
		let lengthShort:UInt16 = try data.readMSBFixedWidthUInt(at: offset + 8)
		self.length = Int(lengthShort)
		let offsetShort:UInt16 = try data.readMSBFixedWidthUInt(at: offset + 10)
		self.offset = Int(offsetShort)
	}
	
	public enum PlatformId : UInt16 {
		case unicode = 0
		case macintosh = 1
		
		///deprecated
		case iso = 2
		
		case windows = 3
		
		case custom = 4
	}
	
	
	public enum NameId : UInt16 {
		case copyright = 0
		case fontFamilyName = 1
		case fontSubFamilyName = 2
		case uniqueFontIdentifier = 3
		case fullFontName = 4
		case version = 5
		
		///iOS wants the postScriptName for UIFont(name:...
		case postScriptName = 6
		case trademark = 7
		case manufacturer = 8
		case designer = 9
		case description = 10
		case vendorUrl = 11
		case designerUrl = 12
		case licenseDescription = 13
		case licenseInfoUrl = 14
		//15 reserved
		case typographicFamilyName = 16
		case typographicSubfamilyName = 17
		case compatibleFullMacintoshName = 18
		case sampleText = 19
		case postScriptCIDFintFontName = 20
		case wwsFamilyName = 21
		case wwsSubFamilyName = 22
		case lightBackgroundPalette = 23
		case darkBackgroundPalette = 24
		case variationsPostScriptNamePrefix = 25
		
	}
	
	public static func englishLanguageIdFormat0(platformId:PlatformId)->UInt16? {
		switch platformId {
		case .macintosh:
			return 0
		case .windows:
			return 0x0409
		default:
			return nil
		}
	}
	
	
}
