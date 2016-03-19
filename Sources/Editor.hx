package;

import kha.Color;
import kha.graphics2.Graphics;
import kha.math.Vector2;
import kha.math.Vector2i;

class Editor
{
	inline static var L_MARGIN:Int = 3;
	inline static var T_MARGIN:Int = 12;
	
	var hex:Hex;
	var renderBufPosY:Int;
	
	var cursor:Vector2i;
	var realCursorPos:Vector2;
	var cursorCountAnim:Int;
	var renderCursor:Bool;
	
	public var updateTaskId:Int;
	
	var buffer:Array<String> = 
		[
			"var x = 80;",
			"function update()",
			"{",
			"  if (btn(0))",
			"    x -= 1;",
			"  else if (btn(1))",
			"    x += 1;",
			"}",
			"function render()",
			"{",
			"  cls();",
			"  rectfill(10, 10, 50, 50, 0xffff0000);",
			"  circfill(x, 80, 20, 0xff228b22);",
			"}"			
		];
	
	public function new(hex:Hex) 
	{
		this.hex = hex;
		cursor = new Vector2i(0, 0);
		realCursorPos = new Vector2(L_MARGIN, T_MARGIN);
		cursorCountAnim = 0;
		renderCursor = true;
	}
	
	public function update()
	{
		cursorCountAnim++;
		if (cursorCountAnim == 15)
		{
			renderCursor = !renderCursor;
			cursorCountAnim = 0;
		}
		
		if (hex.btnp(0))
		{
			if (cursor.x > 0)
			{
				cursor.x--;
				realCursorPos.x = L_MARGIN + (cursor.x * 4);
			}
		}
		else if (hex.btnp(1))
		{
			cursor.x++;
			realCursorPos.x = L_MARGIN + (cursor.x * 4);
		}
		else if (hex.btnp(2))
		{
			if (cursor.y > 0)
			{
				cursor.y--;
				realCursorPos.y = T_MARGIN + (cursor.y * 8);
			}
		}
		else if (hex.btnp(3))
		{
			cursor.y++;
			realCursorPos.y = T_MARGIN + (cursor.y * 8);
		}
	}
	
	inline public function getBuffer():String
	{
		var str = buffer.join('');
		trace(str);
		
		return str;
	}
	
	public function render(g2:Graphics)
	{
		g2.color = 0xff8a8a8a;
		g2.fillRect(0, 0, 128, 9);		
		hex.print('Editor', 3, 2);
		
		if (renderCursor)
			hex.rectfill(realCursorPos.x - 1, realCursorPos.y - 1, realCursorPos.x + 4, realCursorPos.y + 5, Color.Red); 
		
		renderBufPosY = T_MARGIN;
		
		for (b in buffer)
		{
			hex.print(b, L_MARGIN, renderBufPosY);
			renderBufPosY += 8;
		}		
	}
}