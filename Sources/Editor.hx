package;

import kha.Assets;
import kha.Color;
import kha.Font;
import kha.Image;
import kha.Key;
import kha.System;
import kha.graphics2.Graphics;
import kha.input.Keyboard;
import kha.math.Vector2;
import kha.math.Vector2i;

class Editor
{	
	inline static var LEFT_MARGIN:Int = 10;
	var topMargin:Int;
	
	var hex:Hex;
	var rcx:Int;
	var rcy:Int;
	
	var cursor:Vector2i;
	var realCursorPos:Vector2;
	var cursorCountAnim:Int;
	var renderCursor:Bool;
	
	public var updateTaskId:Int;	
		
	var panelHeight:Int;
	
	var buffer:Array<String>;
	
	var sprites:Image;
	
	var windowWidth:Int;
	var windowHeight:Int;	
	
	public function new(hex:Hex) 
	{
		this.hex = hex;
		buffer = new Array<String>();
		buffer.push('');		
		
		panelHeight = 2 + hex.lineHeight + 2;
		topMargin = panelHeight + 9;
		
		realCursorPos = new Vector2(LEFT_MARGIN, topMargin);
		cursor = new Vector2i(0, 0);
		cursorCountAnim = 0;
		renderCursor = true;
		
		sprites = Assets.images.sprites;
		
		windowWidth = System.windowWidth();
		windowHeight = System.windowHeight();
		
		Input.addNewLine = addNewLine;
		Input.addChar = addChar;
		Input.removeChar = removeChar;		
	}
	
	public function update()
	{
		checkArrowKeys();
		
		cursorCountAnim++;
		if (cursorCountAnim == 15)
		{
			renderCursor = !renderCursor;
			cursorCountAnim = 0;
		}
	}
	
	function addNewLine():Void
	{
		if (cursor.y == (buffer.length - 1))
		{
			buffer.push('');
			cursor.y++;
			cursor.x = 0;
			realCursorPos.x = LEFT_MARGIN;
			calcRealCursorY();
		}
		else
		{
			buffer.insert(cursor.y + 1, '');
			
			if (cursor.x < buffer[cursor.y].length)
			{
				buffer[cursor.y + 1] = buffer[cursor.y].substr(cursor.x);
				buffer[cursor.y] = buffer[cursor.y].substr(0, cursor.x);
				cursor.y++;
				
				if (cursor.x > buffer[cursor.y].length)
				{
					cursor.x = buffer[cursor.y].length;
					calcRealCursorX();
				}
			}
			
			calcRealCursorY();
		}		
	}
	
	function removeChar(direction:Int):Void
	{
		// backspace
		if (direction == -1)
		{
			// line with text
			if (buffer[cursor.y].length > 0)
			{
				buffer[cursor.y] = buffer[cursor.y].substr(0, cursor.x - 1);
				cursor.x--;
				calcRealCursorX();
			}
			// empty line
			else
			{
				if (cursor.y > 0)
				{
					buffer.splice(cursor.y, 1);
					cursor.y--;
					cursor.x = buffer[cursor.y].length;
					calcRealCursorX();
					calcRealCursorY();
				}
			}
		}
		// delete
		else
		{
			
		}
	}
	
	function addChar(char:String):Void
	{
		// empty or the end of the line
		if ((buffer[cursor.y].length == 0) || (cursor.x == buffer[cursor.y].length))
			buffer[cursor.y] += char;
		else
			buffer[cursor.y] = buffer[cursor.y].substr(0, cursor.x) + char
			+ buffer[cursor.y].substr(cursor.x + 1);
			
		cursor.x++;
		calcRealCursorX();
	}
	
	function checkArrowKeys():Void
	{
		// left
		if (hex.btnp(0))
		{
			if (cursor.x > 0)
			{
				cursor.x--;
				calcRealCursorX();
			}
		}
		// right
		else if (hex.btnp(1))
		{
			if (cursor.x < buffer[cursor.y].length)
			{
				cursor.x++;
				calcRealCursorX();
			}
		}
		// up
		else if (hex.btnp(2))
		{
			if (cursor.y > 0)
			{
				cursor.y--;
				calcRealCursorY();
			}
		}
		// down
		else if (hex.btnp(3))
		{
			if (cursor.y < (buffer.length - 1))
			{
				cursor.y++;
				if (cursor.x > buffer[cursor.y].length)
				{
					cursor.x = buffer[cursor.y].length;
					calcRealCursorX();
				}
				
				calcRealCursorY();
			}
		}
	}
	
	inline public function getBuffer():String
	{		
		return buffer.join(' ');
	}
	
	public function render(g2:Graphics)
	{
		// panel
		g2.color = 0xff8a8a8a;
		g2.fillRect(0, 0, windowWidth, panelHeight);
		
		// panel shadown
		g2.color = Color.Black;
		g2.pushOpacity(0.2);
		g2.fillRect(0, panelHeight, windowWidth, 3);
		g2.popOpacity();
		
		// cursor
		if (renderCursor)
			hex.rectfill(realCursorPos.x - 1, realCursorPos.y + 2, realCursorPos.x + 2, realCursorPos.y + hex.lineHeight + 6, Color.Red); 
		
		// text
		rcy = topMargin;
				
		g2.color = Color.White;
		
		for (y in 0...buffer.length)
		{
			if (buffer[y].length > 0)			
				hex.print(buffer[y], LEFT_MARGIN, rcy);			
			rcy += hex.lineHeight + 2;
		}		
	}	
	
	function calcRealCursorX():Void
	{
		realCursorPos.x = LEFT_MARGIN;
		
		if (cursor.x > 0)
			realCursorPos.x += hex.getTextWidth(buffer[cursor.y].substr(0, cursor.x));
	}
	
	function calcRealCursorY():Void
	{
		realCursorPos.y = topMargin;
			
		if (cursor.y > 0)	
			realCursorPos.y += (cursor.y * (hex.lineHeight + 2));
	}
}