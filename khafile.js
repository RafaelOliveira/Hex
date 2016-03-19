var project = new Project('Hex');

project.addAssets('Assets/**');
project.addSources('Sources');
project.addSources('C:\\HaxeToolkit\\haxe\\lib\\hscript\\git');

project.windowOptions.width = 540;
project.windowOptions.height = 540;

return project;
