package funkin;

import backend.scripting.*;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.ds.StringMap;
import lime.math.Vector2;

typedef Positions =
{
	var boyfriend:Vector2;
	var girlfriend:Vector2;
	var opponent:Vector2;
}

typedef CameraSettings =
{
	var offsets:Positions;
	var speed:Float;
	var defaultZoom:Float;
}

typedef SkipSettings =
{
	var defaultCountdown:Bool;
	var healthCheck:Bool;
}

class Stage extends FlxTypedGroup<FlxBasic>
{
	private static final DEFAULT:String = 'stage';

	// Contains metadata from psych stages and some extra stuff
	// Default positions
	public var positions:Positions = {
		boyfriend: new Vector2(770, 100),
		girlfriend: new Vector2(400, 130),
		opponent: new Vector2(100, 100)
	};

	public var hide_girlfriend:Bool = false;

	// Camera settings
	public var camera_settings:CameraSettings = {
		offsets: {
			boyfriend: new Vector2(0, 0),
			girlfriend: new Vector2(0, 0),
			opponent: new Vector2(0, 0)
		},
		speed: 1,
		defaultZoom: 1
	};

	// Skip
	public var skip:SkipSettings = {
		defaultCountdown: false,
		healthCheck: false
	};

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
