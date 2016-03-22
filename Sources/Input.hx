package;

import kha.input.Keyboard;
import kha.Key;

/**
 * Class used to receive typed letters from the keyboard
 */
class Input
{
	/** 
	 * Temp variable to convert keycodes 
	 */
	static var charCode:Int;
	
	public static var addNewLine:Void->Void;
	public static var removeChar:Int->Void;
	public static var addChar:String->Void;
		
	/**
	 * Register the events to receive input
	 * In javascript it uses a html event to receive the correct keycodes
	 * from the keyboard.
	 */
	public static function activate(value:Bool):Void
	{
		if (value)
		{
			Keyboard.get().notify(onKeyDown, null);
			
			#if js
			var canvas = js.Browser.document.getElementById('khanvas');
			canvas.onkeypress = keyPress;
			#end
		}
		else
		{
			Keyboard.get().remove(onKeyDown, null);
			
			#if js
			var canvas = js.Browser.document.getElementById('khanvas');
			canvas.onkeypress = null;
			#end
		}
	}

	/**
	 * For javascript it receives only the space key, backspace and enter.
	 * Others letters are handled by the keyPress function. Others targets
	 * receive all the letters here.
	 */
	static function onKeyDown(key:Key, char:String)
	{
		if (key == Key.CHAR)
		{
			#if js
			if (char == ' ')
			#end
				addChar(char);
		}
		else
		{
			var keyChar = key.getName().toLowerCase();
			
			if (keyChar == 'backspace')
				removeChar(-1);
			else if (keyChar == 'enter')
				addNewLine();
		}
	}
	
	#if js
	static function keyPress(event:js.html.KeyboardEvent)
	{
		event.stopPropagation();

		var char = String.fromCharCode(event.which);
		
		charCode = char.charCodeAt(0);	
		
		if (charCode > 32 && charCode < 126)
			addChar(char);
	}
	#end
}