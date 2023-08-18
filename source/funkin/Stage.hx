package funkin;

import backend.scripting.*;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.ds.StringMap;

class Stage extends FlxTypedGroup<FlxBasic>
{
	private static final DEFAULT:String = 'stage';

	// Contains metadata from psych stages and some extra stuff
	// Default positions
	public var boyfriend:Array<Float> = [770, 100];
	public var girlfriend:Array<Float> = [400, 130];
	public var opponent:Array<Float> = [100, 100];

	public var hide_girlfriend:Bool = false;

	public var camera_boyfriend:Array<Float> = [0, 0];
	public var camera_opponent:Array<Float> = [0, 0];
	public var camera_girlfriend:Array<Float> = [0, 0];
	public var camera_speed:Float = 1;

	public var defaultCamZoom:Float = 1;

	public var skip_defaultCountdown:Bool = false;

	private var module:ForeverModule;

	public function new(stage:String)
	{
		super();

		var exposure:StringMap<Dynamic> = new StringMap<Dynamic>();
		exposure.set('stage', this);
		exposure.set('add', add);
		exposure.set('remove', remove);

		module = ScriptHandler.loadModule(stage, 'stages/$stage', exposure, DEFAULT);
		if (module.exists('onCreate'))
			module.get('onCreate')();
	}
}
