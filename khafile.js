var project = new Project('Hex');

project.addAssets('Assets/**');
project.addSources('Sources');
project.addSources('C:\\HaxeToolkit\\haxe\\lib\\hscript\\git');

project.windowOptions.width = 640;
project.windowOptions.height = 480;

return project;
