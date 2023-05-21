package window.ui;

import flixel.FlxG;
import openfl.Lib;
import openfl.display.Sprite;

// Made so I can update code automatically across files that extend this class
class Tray extends OFLSprite
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
		active = false;
		visible = false;

		super();

		screenCenter();
	}

	override public function screenCenter()
	{
		// Reflect width
		var rWidth:Float = Reflect.getProperty(this, "_width");
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		x = (0.5 * (Lib.current.stage.stageWidth - (Math.isNaN(rWidth) ? width : rWidth) * _defaultScale));
	}
}
