package funkin;

import backend.ScriptHandler;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.ds.StringMap;

class Stage extends FlxTypedGroup<FlxBasic>
{
	private static final DEFAULT:String = 'stage';

	public var defaultCamZoom:Float = 1;
	public var stageBuild:ForeverModule;

	public function new(stage:String)
	{
		super();

		var exposure:StringMap<Dynamic> = new StringMap<Dynamic>();
		exposure.set('stage', this);
		exposure.set('add', add);

		stageBuild = ScriptHandler.loadModule(stage, 'stages/$stage', exposure, DEFAULT);
		if (stageBuild.exists('onCreate'))
			stageBuild.get('onCreate')();

		trace('Loaded $stage successfully');
	}
}
