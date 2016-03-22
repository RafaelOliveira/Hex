package;

import kha.Image;
import kha.System;
import kha.Scheduler;
import kha.Scaler;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import hscript.Expr.Error;

class Game
{
	var hex:Hex;
	var parser:Parser;
	var interp:Interp;
	var program:Expr;
	var errorCatched:Bool;
	
	var start:Bool;
	
	public function new(hex:Hex) 
	{
		this.hex = hex;
		
		parser = new Parser();
		interp = new Interp();
		start = true;
		
		setupInterp();
	}
	
	public function run(script:String)
	{
		errorCatched = false;
		
		try
		{
			script = getScriptConverted(script);
			
			#if debug
			trace(script);
			#end
			
			program = parser.parseString(script);
		}
		catch (e:Error)
		{
			errorCatched = true;
			trace('Error in line: ${parser.line}');
		}
		
		if (!errorCatched)
		{
			//interp.variables.set('backbuffer', hex.backbuffer);
			interp.execute(program);
		}
	}
	
	/**
	 * Pass Kha classes and hex to the parser
	 */
	public function setupInterp():Void
	{
		interp.variables.set('System', System);
		interp.variables.set('Scheduler', Scheduler);
		interp.variables.set('Scaler', Scaler);		
		interp.variables.set('_hex', hex);
		interp.variables.set('backbuffer', hex.backbuffer);	
		interp.variables.set('MODE_GAME', Project.MODE_GAME);	
	}
	
	public function setupMode(mode:Int):Void
	{
		interp.variables.set('mode', mode);
	}
	
	/**
	 * Injects in the script the calls to the Kha classes
	 * and prefixes the api with the hex variable
	 */
	function getScriptConverted(script:String):String
	{
		var renderScript:String = "
			function _render(framebuffer) 
			{
				if (mode == MODE_GAME)
				{
					backbuffer.g2.begin(false);
					render();
					backbuffer.g2.end();
				
					framebuffer.g2.begin();		
					Scaler.scale(backbuffer, framebuffer, System.screenRotation);
					framebuffer.g2.end();
				}
			}
		
		";
		
		var updateScript:String = "
			function _update()
			{
				_hex.hexUpdateTime();
				update();
				_hex.hexUpdateInput();
			}
			
		";
		
		var updateWithNoUserUpdateScript:String = "
			function _update()
			{
				_hex.hexUpdateTime();
				_hex.hexUpdateInput();
			}
			
		";
		
		var endScriptRegisterRender:String = "
		
			_hex.updateTaskId = Scheduler.addTimeTask(_update, 0, 1 / 30);
			System.notifyOnRender(_render);
		";
		
		var endScript:String = "
		
			_hex.updateTaskId = Scheduler.addTimeTask(_update, 0, 1 / 30);
		";
		
		script = script.toLowerCase();
		
		var firstPass =       ['print', 'circfill', 'rectfill', 'rndi', 'btnp'];
		var firstPassSwitch = ['pri-t', 'c-ircfill', 'r-ectfill', 'r-ndi', 'b-tnp'];
		
		var api = ['clip', 'beginPx', 'endPx', 'pget', 'pset', 'cls', 'camera', 'circ', 'line',
				   'rect', 'spr', 'PI', 'int', 'min', 'max', 'rnd', 'sin', 'cos', 'btn', 'distance', 'rectCollision'];
		
		for (i in 0...firstPass.length)
			script = StringTools.replace(script, firstPass[i], firstPassSwitch[i]);
		
		for (a in api)		
			script = StringTools.replace(script, a, '_hex.${a}');
			
		for (i in 0...firstPass.length)
			script = StringTools.replace(script, firstPassSwitch[i], firstPass[i]);
			
		for (f in firstPass)
			script = StringTools.replace(script, f, '_hex.${f}');
			
		var addUserUpdate = true;
		if (script.indexOf('function update()') == -1)
			addUserUpdate = false;
			
		if (start)
		{
			start = false;
			if (addUserUpdate)
				return renderScript + updateScript + script + endScriptRegisterRender;
			else
				return renderScript + updateWithNoUserUpdateScript + script + endScriptRegisterRender;
		}
		else
		{
			if (addUserUpdate)
				return renderScript + updateScript + script + endScript;
			else
				return renderScript + updateWithNoUserUpdateScript + script + endScript;
		}
	}
}