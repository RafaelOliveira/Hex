package;

import kha.System;

class Main
{
	static var project:Project;
	
	public static function main()
	{
		kha.System.init({ title : 'Hex', width : 540, height : 540 }, function() {
			kha.Assets.loadEverything(function() {
				new Project();
			});
		});
	}
}