# SwiftTrueTypeFont
Pure-Swift reading of the True Type Font (.ttf) file format, and conformance to `SwiftGraphicsCore`'s `Font`.

This is a work in progress.
The TrueType / OpenType font specs are massive, [https://docs.microsoft.com/en-us/typography/opentype/spec/otff](https://docs.microsoft.com/en-us/typography/opentype/spec/otff),[https://developer.apple.com/fonts/TrueType-Reference-Manual/RM05/Chap5.html#FDEF](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM05/Chap5.html#FDEF).    

## For users:

### Read a `.ttf` file

```swift
import SwiftGraphicsCore
import SwiftTrueTypeFont
let data:Data = ... //read data from a *.ttf or *.otf file.
let trueTypeFont:TrueTypeFont? = try? TrueTypeFont(data:data)
```

### Rendering a font

`TrueTypeFont` comforms to `SwiftGraphicsCore`'s `Font`, which means that in order to render it, you have to provide values for the options.  In particular, you need to provide an option value for the size in order to obtain a `RenderingFont`.  Only a `RenderingFont` can make glyphs directly.

Here's an example of getting a rendering font with size 17.0 from the font.

```swift
let font:Font = trueTypeFont
let values:[FontOptionValue] = font.options.compactMap({ option in
        guard option.name == String.FontOptionNameSize else { return nil }
        return option.value(14.0)
	})
guard let renderingFont:RenderingFont = font.rendering(options:values) else { /* fail */ } 
```

The rendering font can then be used with the `drawText(`  method on any `GraphicsContext`.

### Getting the PostScript name of the font, suitable for use in `UIFont(name:...` in iOS.

`let name:String? = font.postScriptName`



## For developers

Conveniences for reading MSBs from `Data` are in `Data+MSB.swift` 

Feel free to contribute; I'm a stickler for making things "Swifty", because I love Swift as a language.  Any functions you write should feature two paths: a detailed path suitable for introspection and throw errors meaningful to a developer who wants to examine the validity of the font, and a simple path that gets a font user quick access to things they want.


## Progress


### Name

- [x] Post script name in English
- [ ] other names in other languages


### Glyph/path conversion
- [x] Simple Glyphs
- [ ] Compound glyphs
- [ ] Modify fill algorithms in SwiftGraphicsCore to support winding number logic & wrench down tight the intersection algorithms.


### CharacterMaps

- [x] Format 0
- [ ] Format 2
- [x] Format 4
- [x] Format 12
- [ ] Other formats
- [x] Unicode 2.0+ encodings
- [ ]  other character encodings on other platforms as a fall back


### Instructing

- [x] procedural, logical, and arithmetic operators except if/else
- [ ] geometry commands
- [ ] CVT / storage commands
