package;

import haxe.xml.Fast;
import haxe.Utf8;
import kha.Image;
import kha.Color;
import kha.Assets;
import kha.Blob;
import kha.math.FastVector2;
import kha.math.FastMatrix3;
import kha.graphics2.Graphics;
	
 typedef BitmapFont = {
	var size:Int;
	var outline:Int;
	var lineHeight:Int;
	var spaceWidth:Int;
	var image:Image;
	var letters:Map<String, Letter>;
}

typedef Letter = {
	var id:Int;
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;
	var xoffset:Int;
	var yoffset:Int;
	var xadvance:Int;
	var kernings:Map<Int, Int>;
}

typedef Line = {
	var text:String;
	var width:Int;
}
	
class BitmapText
{
	var g2:Graphics;
		
	static var spaceCharCode:Int = ' '.charCodeAt(0);

	/** Stores a list of all bitmap fonts into a dictionary */
	static var fontCache:Map<String, BitmapFont>;
	
	public var font:BitmapFont;
	
	var cursorX:Float;
	
	var hex:Hex;
	
	/**
	 * Loads the bitmap font from cache. Remember to call loadFont first before
	 * creating new a BitmapText.
	 */
	public function new(g2:Graphics, hex:Hex, fontName:String):Void
	{
		this.g2 = g2;
		this.hex = hex;
		cursorX = 0;
		
		if (fontCache != null && fontCache.exists(fontName))
			font = fontCache.get(fontName);
		else			
			trace('Failed to init BitmapText with "${fontName}"');
	}
	
	public function print(str:String, x:Float, y:Float, ?color:Color = 0xffffffff):Void 
	{
		g2.color = color;
		cursorX = 0;
		
		for (i in 0...str.length)
		{
			var char = str.charAt(i); // get letter
			//var charCode = Utf8.charCodeAt(char, 0); // get letter id
			var letter = font.letters.get(char); // get letter data

			// If the letter data exists, then we will render it.
			if (letter != null)
			{
				// If the letter is NOT a space, then render it.
				if (letter.id != spaceCharCode)
				{					
					g2.drawScaledSubImage(
						font.image,
						letter.x,
						letter.y,
						letter.width,
						letter.height,
						x + cursorX + letter.xoffset - hex.camX,
						y + letter.yoffset - hex.camY,
						letter.width,
						letter.height);

					// Add kerning if it exists. Also, we don't have to
					// do this if we're already at the last character.
					if (i != (str.length - 1))
					{
						// Get next char's code
						var charNext = str.charAt(i + 1);
						var charCodeNext = Utf8.charCodeAt(charNext, 0);

						// If kerning data exists, adjust the cursor position.
						if (letter.kernings.exists(charCodeNext))							
							cursorX += letter.kernings.get(charCodeNext);							
					}

					// Move cursor to next position, with padding.
					cursorX += (letter.xadvance + font.outline);
				}
				else
				{
					// If this is a space character, move cursor
					// without rendering anything.
					cursorX += font.spaceWidth;
				}
			}
			else
				// Don't render anything if the letter data doesn't exist.
				trace('letter data doesn\'t exist: $char');
		}				
	}
	
	public static function getFont(fontName:String):BitmapFont
	{
		if (fontCache != null && fontCache.exists(fontName))
			return fontCache.get(fontName);
		else
		{
			trace('Failed to load font "${fontName}"');
			return null;
		}
	}
	
	public function getTextWidth(str:String):Int
	{
		var width = 0;
		var char:String;
		var letter:Letter;
		
		for (i in 0...str.length)
		{
			char = str.charAt(i);
			
			if (char != ' ')
			{				
				letter = font.letters.get(char);
				width += (letter.xadvance + font.outline);
			}
			else
				width += font.spaceWidth;
		}
		
		return width;
	}
	
	/**
	 * Do this first before creating new WynBitmapText, because we
	 * need to process the font data before using.
	 */
	public static function loadFontXmlFormat(fontName:String, fontImage:Image, fontData:Blob):Void
	{
		// We'll store each letter's data into a dictionary here later.
		var letters = new Map<String, Letter>();

		var blobString:String = fontData.toString();
		var fullXml:Xml = Xml.parse(blobString);
		var fontNode:Xml = fullXml.firstElement();
		var data = new Fast(fontNode);

		// If the font file doesn't have a ' ' character,
		// this will be a default spacing for it.
		var spaceWidth = 8;

		// NOTE: Each of these attributes are in the .fnt XML data.
		var chars = data.node.chars;
		for (char in chars.nodes.char)
		{
			var letter:Letter = {
				id: Std.parseInt(char.att.id),
				x: Std.parseInt(char.att.x),
				y: Std.parseInt(char.att.y),
				width: Std.parseInt(char.att.width),
				height: Std.parseInt(char.att.height),
				xoffset: Std.parseInt(char.att.xoffset),
				yoffset: Std.parseInt(char.att.yoffset),
				xadvance: Std.parseInt(char.att.xadvance),
				kernings: new Map<Int, Int>()
			}

			// NOTE on xadvance:
			// http://www.angelcode.com/products/bmfont/doc/file_format.html
			// xadvance is the padding before the next character
			// is rendered. Spaces may have no width, so we assign
			// them here specifically for use later. Otherwise,
			// every other letter data has no spaceWidth value.
			if (letter.id == spaceCharCode)
				spaceWidth = letter.xadvance;

			// Save the letter's data into the dictioanry
			letters.set(String.fromCharCode(letter.id), letter);
		}

		// If this fnt XML has kerning data for each letter,
		// process them here. Kernings are UNIQUE padding
		// between each letter to create a pleasing visual.
		// As an idea, Bevan.ttf has about 1000+ kerning data.
		if (data.hasNode.kernings)
		{
			var kernings = data.node.kernings;
			var letter:Letter;
			for (kerning in kernings.nodes.kerning)
			{
				var firstId = Std.parseInt(kerning.att.first);
				var secondId = Std.parseInt(kerning.att.second);
				var amount = Std.parseInt(kerning.att.amount);

				letter = letters.get(String.fromCharCode(firstId));
				letter.kernings.set(secondId, amount);
			}
		}

		// Create the dictionary if it doesn't exist yet
		if (fontCache == null)
			fontCache = new Map<String, BitmapFont>();

		// Create new font data
		var font:BitmapFont = {
			size: Std.parseInt(data.node.info.att.size), // this original size this font's image was exported as
			outline: Std.parseInt(data.node.info.att.outline), // outlines are considered padding too
			lineHeight: Std.parseInt(data.node.common.att.lineHeight), // original vertical padding between texts
			spaceWidth: spaceWidth, // remember, this is only for space character
			image: fontImage, // the font image sheet
			letters: letters // each letter's data
		}

		// Add this font data to dictionary, finally.
		fontCache.set(fontName, font);
	}
	
	public static function loadFontTextFormat(fontName:String, fontImage:Image, fontData:Blob):Void
	{
		var size:Int = 0;
		var outline:Int = 0;
		var lineHeight:Int = 0;
	
		// We'll store each letter's data into a dictionary here later.
		var letters = new Map<String, Letter>();
		
		var rawData = fontData.toString();
		
		var trim1 = ~/^ +| +$/g; // removes all spaces at beginning and end
		var trim2 = ~/ +/g; // merges all spaces into one space
		
		rawData = trim1.replace(rawData, ""); // remove trailing spaces first
		rawData = trim2.replace(rawData, " "); // merge all spaces into one
		
		var data = rawData.split('\n');
		
		// If the font file doesn't have a ' ' character,
		// this will be a default spacing for it.
		var spaceWidth = 8;
		
		var tokens:Array<String>;
		var item:Array<String>;
		
		for (line in data)
		{
			if (line.substr(0, 4) == 'info')
			{
				tokens = line.substr(5).split(' ');
				
				for (tk in tokens)
				{
					item = tk.split('=');
					
					if (item[0] == 'size')
						size = Std.parseInt(item[1]);
					else if (item[0] == 'outline')
						outline = Std.parseInt(item[1]);
				}
			}
			else if (line.substr(0, 6) == 'common')
			{
				tokens = line.substr(7).split(' ');
				
				for (tk in tokens)
				{
					item = tk.split('=');
					
					if (item[0] == 'lineHeight')
					{
						lineHeight = Std.parseInt(item[1]);
						break;
					}
				}
			}
			else if (line.substr(0, 5) == 'char ')
			{
				tokens = line.substr(5).split(' ');				
				
				var letter:Letter = {
					id: Std.parseInt(tokens[0].split('=')[1]),
					x: Std.parseInt(tokens[1].split('=')[1]),
					y: Std.parseInt(tokens[2].split('=')[1]),
					width: Std.parseInt(tokens[3].split('=')[1]),
					height: Std.parseInt(tokens[4].split('=')[1]),
					xoffset: Std.parseInt(tokens[5].split('=')[1]),
					yoffset: Std.parseInt(tokens[6].split('=')[1]),
					xadvance: Std.parseInt(tokens[7].split('=')[1]),
					kernings: new Map<Int, Int>()
				}

				// NOTE on xadvance:
				// http://www.angelcode.com/products/bmfont/doc/file_format.html
				// xadvance is the padding before the next character
				// is rendered. Spaces may have no width, so we assign
				// them here specifically for use later. Otherwise,
				// every other letter data has no spaceWidth value.
				if (letter.id == spaceCharCode)
					spaceWidth = letter.xadvance;

				// Save the letter's data into the dictioanry
				letters.set(String.fromCharCode(letter.id), letter);
			}
		}
		
		// Create the dictionary if it doesn't exist yet
		if (fontCache == null)
			fontCache = new Map<String, BitmapFont>();
			
		// Create new font data
		var font:BitmapFont = {
			size: size, // this original size this font's image was exported as
			outline: outline, // outlines are considered padding too
			lineHeight: lineHeight, // original vertical padding between texts
			spaceWidth: spaceWidth, // remember, this is only for space character
			image: fontImage, // the font image sheet
			letters: letters // each letter's data
		}

		// Add this font data to dictionary, finally.
		fontCache.set(fontName, font);
	}	
}