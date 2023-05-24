package funkin;

import backend.ScriptHandler;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.ds.StringMap;

class Stage extends FlxTypedGroup<FlxBasic>
{
	private static final DEFAULT:String = 'stage';

	// Default positions
	public var boyfriend:Array<Float> = [770, 100];
	public var opponent:Array<Float> = [100, 100];

	public var defaultCamZoom:Float = 1;
	public var module:ForeverModule;

	public function new(stage:String)
	{
		super();

		var exposure:StringMap<Dynamic> = new StringMap<Dynamic>();
		exposure.set('stage', this);
		exposure.set('add', add);

		module = ScriptHandler.loadModule(stage, 'stages/$stage', exposure, DEFAULT);
		if (module.exists('onCreate'))
			module.get('onCreate')();
	}

	override public function update(elapsed:Float)
	{
		if (module.exists('onUpdate'))
			module.get('onUpdate')(elapsed);

		super.update(elapsed);

		if (module.exists('onUpdatePost'))
			module.get('onUpdatePost')(elapsed);
	}
}
