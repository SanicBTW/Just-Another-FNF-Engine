package window_ui;

import flixel.FlxG;
import flixel.math.FlxMath;
import openfl.text.TextField;
import openfl.text.TextFormat;
#if flash
import openfl.Lib;
import openfl.events.Event;
#end

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FramerateCounter extends TextField
{
	public var currentFPS(default, null):Float;

	@:noCompletion private var frames:Int = 0;
	@:noCompletion private var prevTime:Float = Date.now().getTime();

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
	}

	@:noCompletion
	private override function __enterFrame(_):Void
	{
		if (!visible)
			return;

		frames++;

		var prevTime:Float = this.prevTime;
		var time:Float = Date.now().getTime();

		if (time > prevTime + 1000)
		{
			currentFPS = FlxMath.roundDecimal((frames * 1000) / (time - prevTime), 2);
			text = 'FPS: $currentFPS';
			this.prevTime = time;
			frames = 0;
		}

		if (currentFPS < FlxG.updateFramerate / 2)
			textColor = 0xFFFF0000;
		else
			textColor = 0xFFFFFFFF;
	}
}
