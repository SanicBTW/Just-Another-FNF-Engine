package window;

import flixel.FlxG;
import openfl.Lib;

// Made so I can update code automatically across files that extend this class
class Tray extends ExSprite
{
	// Default scale for the tray, each tray class will have its own width and height
	private var _defaultScale:Float = 2.0;

	// Game sizes
	private var gWidth(get, null):Int;

	@:noCompletion
	private function get_gWidth():Int
		return Std.int(FlxG.game.width);

	private var gHeight(get, null):Int;

	@:noCompletion
	private function get_gHeight():Int
		return Std.int(FlxG.game.height);

	override public function new()
	{
		super();
		active = false;
		visible = false;

		screenCenter();
	}

	override public function screenCenter()
	{
		// Reflect width
		var rWidth:Float = Reflect.getProperty(this, "_width");
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		x = (0.5 * (Lib.current.stage.stageWidth - (Math.isNaN(rWidth) ? width : rWidth) * _defaultScale) - FlxG.game.x);
	}
}
