package;

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
	
	public function new(hex:Hex) 
	{
		this.hex = hex;
		
		parser = new Parser();
		interp = new Interp();
		
		setupInterp();
	}
	
	public function run(script:String)
	{
		try
		{			
			program = parser.parseString(getScriptConverted(script));
		}
		catch (e:Error)
		{
			trace(parser.line);
		}
		
		interp.execute(program);
	}

	function setupInterp():Void
	{
		interp.variables.set('System', System);
		interp.variables.set('Scheduler', Scheduler);
		interp.variables.set('Scaler', Scaler);
		interp.variables.set('backbuffer', hex.backbuffer);
		
		
		interp.variables.set('_hex', hex);
	}
	
	function getScriptConverted(script:String):String
	{
		var beginScript:String = "
			function _render(framebuffer) 
			{
				backbuffer.g2.begin(false);
				render();
				backbuffer.g2.end();
				
				framebuffer.g2.begin();		
				Scaler.scale(backbuffer, framebuffer, System.screenRotation);
				framebuffer.g2.end();
			}
			
			function _update()
			{
				_hex.hexUpdateTime();
				update();
				_hex.hexUpdateInput();
			}
			
		";
		
		var endScript:String = "
		
			_hex.updateTaskId = Scheduler.addTimeTask(_update, 0, 1 / 30);
			System.notifyOnRender(_render);
		";
	
		var copyScript = script.toString();
		
		var firstPass =       ['print', 'circfill', 'rectfill', 'rndi', 'btnp'];
		var firstPassSwitch = ['pri-t', 'c-ircfill', 'r-ectfill', 'r-ndi', 'b-tnp'];
		
		var api = ['clip', 'beginPx', 'endPx', 'pget', 'pset', 'cls', 'camera', 'circ', 'line',
				   'rect', 'spr', 'PI', 'int', 'min', 'max', 'rnd', 'sin', 'cos', 'btn', 'distance', 'rectCollision'];
		
		for (i in 0...firstPass.length)
			copyScript = StringTools.replace(copyScript, firstPass[i], firstPassSwitch[i]);
		
		for (a in api)		
			copyScript = StringTools.replace(copyScript, a, '_hex.${a}');
			
		for (i in 0...firstPass.length)
			copyScript = StringTools.replace(copyScript, firstPassSwitch[i], firstPass[i]);
			
		for (f in firstPass)
			copyScript = StringTools.replace(copyScript, f, '_hex.${f}');
			
		return beginScript + copyScript + endScript;
	}
}