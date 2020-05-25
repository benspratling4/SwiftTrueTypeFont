//
//  TrueTypeFont.swift
//  
//
//  Created by Ben Spratling on 5/25/20.
//

import Foundation
import SwiftGraphicsCore

public enum TrueTypeFontError : Error {
	
	case invalidTableRecord
	case missingTable(String)
	
}


///Basic data type for reading from a .ttf file
///WIP instructing is WIP and not activated yet
public class TrueTypeFont : Font {
	
	public init(data:Data) throws {
		sfnt = try SFNT(data: data)
		//now extract required tables
		nameTable = try NameTable(data:data, in:try sfnt.tableRange(tag:"name"))
		headerTable = try HeaderTable(data: data, in: try sfnt.tableRange(tag:"head"))
		horizontalHeaderTable = try HorizontalHeaderTable(data: data, in: try sfnt.tableRange(tag: "hhea"))
		maxTable = try MaxTable(data: data, in: try sfnt.tableRange(tag:"maxp"))
		horizontalMetricsTable = try HorizontalMetricsTable(data: data, in: try sfnt.tableRange(tag:"hmtx")
			,numberOfHMetrics:Int(horizontalHeaderTable.numberOfHMetrics)
			,numGlyphs: maxTable.numberOfGlyphs)
		characterMapTable = try CharacterMapTable(data: data, in: try sfnt.tableRange(tag: "cmap"))
		locationTable = try LocationTable(data:data
			,in:try sfnt.tableRange(tag:"loca")
			,numGlyphs:maxTable.numberOfGlyphs
			,indexToLocFormat:headerTable.indexToLocFormat)
		glyphTable = try GlyphTable(data: data, in: try sfnt.tableRange(tag:"glyf"))
	}
	
	//MARK: - FontCompliance
	
	public var name:String { nameTable.englishPostScriptName ?? "" }
	
	public var options:[FontOption] {
		return [
			FontSizeOption(minValue: Float32(headerTable.lowestRecPPEM))
		]
	}
	
	public func rendering(options:[FontOptionValue])->RenderingFont? {
		let size:Float32 = (options.filter({$0.option.name == String.FontOptionNameSize}).first as? FontSizeOptionValue)?.size ?? 12.0
		return TrueTypeRenderingFont(font: self, ppem: SGFloat(size), optionValues:options)
	}
	
	
	//MARK: - Instance methods
	
	public var postScriptName:String? {
		nameTable.englishPostScriptName
	}
	
	//MARK: - Internal guts
	
	let sfnt:SFNT
	let nameTable:NameTable
	let headerTable:HeaderTable
	let horizontalHeaderTable:HorizontalHeaderTable
	let maxTable:MaxTable
	let horizontalMetricsTable:HorizontalMetricsTable
	let characterMapTable:CharacterMapTable
	let locationTable:LocationTable
	let glyphTable:GlyphTable
	
}


//concrete implementations of the font option & option value protocols.
//it shouldn't be necessary to make these public, since they conform to the protocols.
//we prefer for people to work with the abstractions, and leave these concrete types internal
internal struct FontSizeOption : FontOption {
	var name:String { return String.FontOptionNameSize }
	var minValue:Float32?
	var maxValue:Float32? { return nil }
	var increment:Float32? { return 1.0 }
	func value(_ value:Float32)->FontOptionValue {
		return FontSizeOptionValue(size: value, option: self)
	}
}


internal struct FontSizeOptionValue : FontOptionValue {
	var size:Float32
	var option:FontOption
}

