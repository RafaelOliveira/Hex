package;

import kha.Assets;
import kha.Color;
import kha.Image;
import kha.Key;
import kha.Scheduler;
import kha.input.Keyboard;
import BitmapText.Letter;

using kha.graphics2.GraphicsExtension;

typedef Graphics1 = kha.graphics1.Graphics;
typedef Graphics2 = kha.graphics2.Graphics;

@:allow(BitmapText)
class Hex
{	
	/** Kha's pixel context */
	public var g1:Graphics1;
	
	/** Kha's 2d context */
	public var g2:Graphics2;
	
	var g2Editor:Graphics2;
	
	/** If should use bilinear filter on render */
	public var bFilter:Bool = false;
		
	var sprites:Image;
	public var backbuffer:Image;
	
	public var bmText:BitmapText;
	
	var totalSpritesCol:Int;
	var tileWidth:Int;
	var tileHeight:Int;
	
	var camX:Float;
	var camY:Float;
	
	// start position of the user content on the sprites
	var sx:Int;
	var sy:Int;
	
	var map:Array<Array<Int>>;
	
	var oldTime:Float = 0;
	var currentTime:Float = 0;
	
	var keysHeld:Map<Int, Bool>;
	var keysPressed:Map<Int, Bool>;
	
	/** The time passed since the last frame */
	public var elapsed:Float = 0;
	
	public var updateTaskId:Int;
	
	public var inEditor:Bool;
	
	public var lineHeight:Int;
	
	public var print:String->Float->Float->?Color->Void;
	public var getTextWidth:String->Int;
	
	public function new(backbuffer:Image, tileWidth:Int, tileHeight:Int)
	{
		this.backbuffer = backbuffer;
		g1 = backbuffer.g1;
		g2 = backbuffer.g2;		
		
		this.tileWidth = tileWidth;
		this.tileHeight = tileHeight;
		
		sprites = Assets.images.sprites;
		totalSpritesCol = Std.int(sprites.width / tileWidth);
		
		camX = 0;
		camY = 0;
		
		sx = 0;
		sy = 16;
		
		keysHeld = new Map<Int, Bool>();
		keysPressed = new Map<Int, Bool>();		
		
		var k = Keyboard.get();
		k.notify(keyDown, keyUp);
	}	
	
	public function setTileSize(width:Int, height:Int):Void
	{
		tileWidth = width;
		tileHeight = height;
	}
	
	public function hexUpdateTime():Void
	{
		oldTime = currentTime;
	    currentTime = Scheduler.time();
		
		elapsed = currentTime - oldTime;
	}
	
	public function hexUpdateInput():Void
	{
		for (key in keysPressed.keys())
			keysPressed.remove(key);		
	}
	
	public function loadBmFont(fontName:String):Void
	{
		if (bmText == null)
			bmText = new BitmapText(g2, this, fontName);
		else
			bmText.font = BitmapText.getFont(fontName);
			
		lineHeight = bmText.font.lineHeight;
		print = bmText.print;
		getTextWidth = bmText.getTextWidth;
	}
	
	inline public function getLetter(char:String):Letter
	{
		return bmText.font.letters.get(char);
	}	
	
	function keyDown(key:Key, char:String)
	{
		switch(key)
		{
			case Key.LEFT:
				keysHeld.set(0, true);
				keysPressed.set(0, true);
			
			case Key.RIGHT:
				keysHeld.set(1, true);
				keysPressed.set(1, true);
			
			case Key.UP:
				keysHeld.set(2, true);
				keysPressed.set(2, true);
			
			case Key.DOWN:
				keysHeld.set(3, true);
				keysPressed.set(3, true);
			
			default:
				if (char == 'z' || char == 'Z')
				{
					keysHeld.set(4, true);
					keysPressed.set(4, true);
				}
				else if (char == 'x' || char == 'X')
				{
					keysHeld.set(5, true);
					keysPressed.set(5, true);
				}
		}
	}
	
	function keyUp(key:Key, char:String)
	{
		switch(key)
		{
			case Key.LEFT:
				keysHeld.set(0, false);
			
			case Key.RIGHT:
				keysHeld.set(1, false);
			
			case Key.UP:
				keysHeld.set(2, false);
			
			case Key.DOWN:
				keysHeld.set(3, false);
			
			default:
				if (char == 'z' || char == 'Z')
					keysHeld.set(4, false);
				else if (char == 'x' || char == 'X')
					keysHeld.set(5, false);
		}
	}
	
	/////// begin of the api ///////
	
	public function clip(?x:Int, ?y:Int, ?w:Int, ?h:Int):Void
	{
		if (x != null && y != null && w != null && h != null)
			g2.scissor(x, y, w, h);
		else
			g2.disableScissor();
	}
	
	/** Call this before draw pixels */
	public function beginPx():Void
	{
		g2.end();
		g1.begin();
	}
	
	/** Call this after draw pixels */
	public function endPx():Void
	{
		g1.end();
		g2.begin(false);
	}
	
	/** Get the color of a pixel at x, y */
	public function pget(x:Int, y:Int):Color
	{
		return backbuffer.at(Std.int(x - camX), Std.int(y - camY));
	}
	
	/** Set the color of a pixel at x, y */
	public function pset(x:Int, y:Int, color:Color):Void
	{
		g1.setPixel(Std.int(x - camX), Std.int(y - camY), color);
	}	
	
	/** Clear the screen */
	inline public function cls(color:Color = 0xff000000):Void
	{		
		g2.clear(color);		
	}
	
	public function camera(?x:Float, ?y:Float):Void
	{
		if (x != null)
			camX = x;
		
		if (y != null)
			camY = y;
		
		if (x == null && y == null)
		{
			camX = 0;
			camY = 0;
		}
	}
	
	/** Draw a circle at x,y with radius r */
	public function circ(x:Float, y:Float, r:Float, color:Color):Void
	{
		g2.color = color;
		g2.drawCircle(x - camX, y - camY, r);
	}
	
	/** Draw a filled circle at x,y with radius r */
	public function circfill(x:Float, y:Float, r:Float, color:Color):Void
	{
		g2.color = color;
		g2.fillCircle(x - camX, y - camY, r);
	}
	
	/** Draw line */
	public function line(x0:Float, y0:Float, x1:Float, y1:Float, color:Color):Void
	{
		g2.color = color;
		g2.drawLine(x0 - camX, y0 - camY, x1 - camX, y1 - camY);			
	}
	
	/** Draw a rectange */
	public function rect(x0:Float, y0:Float, x1:Float, y1:Float, color:Color):Void
	{
		g2.color = color;
		g2.drawRect(x0 - camX, y0 - camY, x1 - x0, y1 - y0);
	}
	
	/** Draw a filled rectange */
	public function rectfill(x0:Float, y0:Float, x1:Float, y1:Float, color:Color):Void
	{
		g2.color = color;
		g2.fillRect(x0 - camX, y0 - camY, x1 - x0, y1 - y0);
	}	
	
	/** Draw a sprite */
	public function spr(id:Int, x:Float, y:Float, w:Int = 1, h:Int = 1, flipX:Bool = false, flipY:Bool = false, ?color:Color = 0xffffffff):Void
	{
		g2.color = color;
		
		if (w == 1 && h == 1)
			g2.drawScaledSubImage(sprites, sx + ((id % totalSpritesCol) * tileWidth), sy + (Std.int(id / totalSpritesCol) * tileHeight), tileWidth, tileHeight, 
			x - camX + (flipX ? tileWidth : 0), y - camY + (flipY ? tileHeight : 0), flipX ? -tileWidth : tileWidth, flipY ? -tileHeight : tileHeight);
		else
		{
			for (i in 0...w)
			{
				for (j in 0...h)
					g2.drawScaledSubImage(sprites, sx + ((id % totalSpritesCol) * tileWidth) + (i * tileWidth), sy + (Std.int(id / totalSpritesCol) * tileHeight) + (j * tileHeight),
					tileWidth, tileHeight, x + (i * tileWidth) - camX, y + (j * tileHeight) - camY, flipX ? -tileWidth : tileWidth,
					flipY ? -tileHeight : tileHeight);
			}
		}
	}
	
	public  var PI(get, null):Float;
	inline function get_PI():Float 
	{
		return Math.PI;
	}
	
	inline public function int(x:Float):Int
	{
		return Std.int(x);	
	}
	
	inline public function min(a:Float, b:Float):Float
	{
		return Math.min(a, b);
	}
	
	inline public function max(a:Float, b:Float):Float
	{
		return Math.max(a, b);
	}
	
	public function rnd(x:Float):Float
	{
		return Math.random() * x;
	}
	
	inline public function rndi(x:Float):Int
	{
		return Std.int(Math.random() * x);
	}
	
	inline public function sin(x:Float):Float
	{
		return Math.sin(x);
	}
	
	inline public function cos(x:Float):Float
	{
		return Math.cos(x);
	}
	
	inline public function distance(x1:Float, y1:Float, x2:Float = 0, y2:Float = 0):Float
	{
		return Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
	}
	
	public function rectCollision(x0:Float, y0:Float, w0:Int, h0:Int, x1:Float, y1:Float, w1:Int, h1:Int):Bool
	{
		var a: Bool;
		var b: Bool;
		
		if (x0 < x1) a = x1 < x0 + w0;
		else a = x0 < x1 + w1;
		
		if (y0 < y1) b = y1 < y0 + h0;
		else b = y0 < y1 + h1;
		
		return a && b;
	}
	
	/** 
	 * Check if a button is being held 
	 */
	public function btn(id:Int):Bool
	{		
		return keysHeld.get(id);
	}
	
	/**
	 * Check if a button was pressed 
	 */
	public function btnp(id:Int):Bool
	{	
		return keysPressed.exists(id);		
	}
}