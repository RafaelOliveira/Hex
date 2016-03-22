package;

import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.Image;
import kha.System;
import kha.Scheduler;
import kha.Scaler;
import kha.graphics2.ImageScaleQuality;
import kha.input.Keyboard;
import kha.Key;

class Project 
{
	public inline static var MODE_EDITOR:Int = -1;
	public inline static var MODE_GAME:Int = 1;
	
	var backbuffer:Image;	
	var hex:Hex;
	
	var editor:Editor;
	var game:Game;
	
	var mode:Int = MODE_EDITOR;

	public function new() 
	{			
		backbuffer = Image.createRenderTarget(640, 480);
		
		BitmapText.loadFontTextFormat('hermit20', Assets.images.hermit20, Assets.blobs.hermit20_fnt);
		
		hex = new Hex(backbuffer, 8, 8);			
		hex.loadBmFont('hermit20');
		
		editor = new Editor(hex);
		game = new Game(hex);		
		
		// the keyboard is used here to switch modes
		var k = Keyboard.get(0);
		k.notify(keyDown, null);
		
		mode = MODE_EDITOR;
		switchMode(true);
	}
	
	/**
	 * Switch between the game and the editors
	 * @param	start	Used to call this function in the start of the app. It switches the mode
	 * without removing the previous update function from the Scheduler.
	 */
	public function switchMode(start:Bool = false)
	{	
		// clearing the screen
		if (!start)
		{
			backbuffer.g2.begin(true, Color.Black);
			backbuffer.g2.end();			
		}		
		
		if (mode == MODE_EDITOR)
		{
			if (!start)
			{
				Scheduler.removeTimeTask(hex.updateTaskId);
				game.setupMode(MODE_EDITOR);
			}
				
			editor.updateTaskId = Scheduler.addTimeTask(update, 0, 1 / 30);
			Input.activate(true);
			
			if (start)
				System.notifyOnRender(render);
		}
		else
		{
			if (!start)
				Scheduler.removeTimeTask(editor.updateTaskId);
				
			game.setupMode(MODE_GAME);
				
			Input.activate(false);			
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
		if (mode == MODE_EDITOR)
		{
			framebuffer.g2.imageScaleQuality = ImageScaleQuality.High;
			
			backbuffer.g2.begin(true, 0xff4169e1);
			editor.render(backbuffer.g2);
			backbuffer.g2.end();
		
			framebuffer.g2.begin();
			Scaler.scale(backbuffer, framebuffer, System.screenRotation);		
			framebuffer.g2.end();
		}
	}
	
	function keyDown(key:Key, char:String):Void
	{
		// switch the modes
		if (key == Key.ESC)
		{
			mode *= -1;
			switchMode();
		}
	}
}