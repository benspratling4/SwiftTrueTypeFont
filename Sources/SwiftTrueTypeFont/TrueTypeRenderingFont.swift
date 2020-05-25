//
//  File.swift
//  
//
//  Created by Ben Spratling on 5/25/20.
//

import Foundation
import SwiftGraphicsCore

public class TrueTypeRenderingFont : RenderingFont {
	
	let trueTypeFont:TrueTypeFont
	let ppem:SGFloat
	init(font:TrueTypeFont, ppem:SGFloat, optionValues:[FontOptionValue]) {
		self.trueTypeFont = font
		self.ppem = ppem
		self.optionValues = optionValues
	}
	
	//MARK: - RenderingFont
	
	public var font:Font {
		return trueTypeFont
	}
	
	public var optionValues:[FontOptionValue]
	
	public func gylphIndexes(text:String)->[Int] {
		///currently only support unicode encoding 3 tables
		guard let table:CharacterEncodingTable = trueTypeFont.characterMapTable.tables.filter({ $0.encodingRecord.platformId == .unicode && $0.encodingRecord.encodingID == 3 }).first else {
			//return missing glyph for every thing
			return text.map { (chracter) -> Int in
				//for now, they're all the missing glyph
				//TODO: support actual character maps
				return 0
			}
		}
		
		return text.unicodeScalars.map { (character) -> Int in
			table.glyphIndex(characterIndex:Int(character.value))
		}
	}
	
	//basically, how wide is this character
	public func glyphAdvances(indices:[Int])->[SGFloat] {
		let glyphOffsets:[Int] = indices.map({ trueTypeFont.locationTable.glyphOffsets[$0] })
		
		let boxes:[GlyphBox] = glyphOffsets.compactMap({ try? trueTypeFont.glyphTable.boundingBox(from: $0) })
		return boxes.map({  ppem * SGFloat($0.xMax - $0.xMin) / SGFloat(trueTypeFont.headerTable.unitsPerEm) })
	}
	
	public func path(glyphIndex:Int)->Path {
		fatalError("write me")
	}
	
	
	//TODO: write me
	
}
