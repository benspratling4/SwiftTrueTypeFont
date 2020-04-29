# SwiftTrueTypeFont
Pure Swift reading of the binary bits of True Type Font (.ttf) Files

This is a work in progress.
The TrueType / OpenType font specs are massive, https://docs.microsoft.com/en-us/typography/opentype/spec/otff.    

## For users:

Read a file

`
let data:Data = ... read data from a *.ttf or *.otf file.
let font = try? TTF(data:data)	
`
### Getting the PostScript name of the font, suitable for use in `UIFont(name:...` in iOS.

`
let name:String? = font?.nameTable?.englishPostScriptName
`

## For developers

Conveniences for reading MSBs from `Data` are in `Data+MSB.swift` 

Feel free to contribute; I'm a stickler for making things "Swifty", because I love Swift as a language.  Any functions you write should feature two paths: a detailed path suitable for introspection and throw errors meaningful to a developer who wants to examine the validity of the font, and a simple path that gets a font user wuick access to things they want.
