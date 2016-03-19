package;

import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.Image;
import kha.System;
import kha.Scheduler;
import kha.Scaler;
import kha.input.Keyboard;
import kha.Key;

class Project 
{
	inline static var MODE_EDITOR:Int = -1;
	inline static var MODE_GAME:Int = 1;
	
	var backbuffer:Image;
	var hex:Hex;
	
	var editor:Editor;
	var game:Game;
	
	// editor or game
	var mode:Int = MODE_EDITOR;
	
	var keyChar:String = '';
	
	public static var the:Project;

	public function new() 
	{	
		backbuffer = Image.createRenderTarget(128, 128);
		
		hex = new Hex(backbuffer, 8, 8);
		hex.loadBmFont('font', 4, 5);
		
		editor = new Editor(hex);
		game = new Game(hex);
		
		var k = Keyboard.get(0);
		k.notify(keyDown, null);
		
		mode = MODE_EDITOR;
		switchMode(true);
	}
	
	public function switchMode(start:Bool = false)
	{	
		if (mode == MODE_EDITOR)
		{
			if (!start)
				Scheduler.removeTimeTask(hex.updateTaskId);
			
			editor.updateTaskId = Scheduler.addTimeTask(update, 0, 1 / 30);
			System.notifyOnRender(render);
		}
		else
		{
			if (!start)
				Scheduler.removeTimeTask(editor.updateTaskId);
			
			// clearing the screen (not working)
			// backbuffer.g2.begin(true, Color.Black);
			// backbuffer.g2.end();
				
			game.run(editor.getBuffer());
		}
	}
	
	function update():Void
	{
		hex.hexUpdateTime();
		editor.update();
		hex.hexUpdateInput();
	}
	
	function render(framebuffer:Framebuffer):Void
	{
		backbuffer.g2.begin(true, 0xff4169e1);
		editor.render(backbuffer.g2);
		backbuffer.g2.end();
		
		framebuffer.g2.begin();		
		Scaler.scale(backbuffer, framebuffer, System.screenRotation);
		framebuffer.g2.end();
	}
	
	function keyDown(key:Key, char:String):Void
	{
		if (key == Key.ESC)
		{
			mode *= -1;
			switchMode();
		}
	}
}