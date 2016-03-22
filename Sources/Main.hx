package;

import kha.System;

class Main
{
	static var project:Project;
	
	public static function main()
	{
		kha.System.init({ title : 'Hex', width : 640, height : 480 }, function() {
			kha.Assets.loadEverything(function() {
				new Project();
			});
		});
	}
}