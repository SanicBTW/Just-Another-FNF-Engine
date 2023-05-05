package window.debug;

import flixel.FlxG;
import flixel.math.FlxMath;
import openfl.text.TextField;
import openfl.text.TextFormat;

class FramerateCounter extends TextField
{
	public var currentFPS(default, null):Float;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 12, 0xFFFFFF);
		text = "FPS: ";

		cacheCount = 0;
		currentTime = 0;
		times = [];
	}

	@:noCompletion
	private override function __enterFrame(deltaTime:Float):Void
	{
		if (!visible)
			return;

		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		currentFPS = FlxMath.roundDecimal((times.length + cacheCount) / 2, 2);

		if (times.length != cacheCount)
			text = 'FPS: $currentFPS';

		if (currentFPS < FlxG.updateFramerate / 2)
			textColor = 0xFFFF0000;
		else
			textColor = 0xFFFFFFFF;

		cacheCount = times.length;
	}
}
