package window;

import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.display.Shape;

class VolumePanel extends ExSprite
{
	private var _defaultScale:Float = 2.0;

	private var _visibleTime:Float = 0;

	private var _width:Int = 240;
	private var _height:Int = 100;

	private var targetX:Float = 0.0;
	private var targetY:Float = 0.0;

	private var _bg:Shape;

	private var gWidth(get, null):Int;

	@:noCompletion
	private function get_gWidth():Int
		return Std.int(FlxG.game.width);

	private var gHeight(get, null):Int;

	@:noCompletion
	private function get_gHeight():Int
		return Std.int(FlxG.game.height);

	override public function create()
	{
		width = _width;
		height = _height;

		_bg = drawRound(0, 0, _width, _height, [15], FlxColor.WHITE, 0.6);
		screenCenter();
		addChild(_bg);

		FlxG.signals.gameResized.add((_, _) ->
		{
			screenCenter();
		});
	}

	override function update(elapsed:Float, deltaTime:Float)
	{
		var lerpVal:Float = flixel.math.FlxMath.bound(1 - (elapsed * 8.6), 0, 1);

		lerpTrack(_bg, "x", targetX, lerpVal);
		lerpTrack(_bg, "y", targetY, lerpVal);

		targetX = (0.5 * (FlxG.mouse.x - _width * _defaultScale));
		targetY = (0.5 * (FlxG.mouse.y - _height * _defaultScale));
	}

	override function screenCenter()
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (openfl.Lib.current.stage.stageWidth - _width * _defaultScale));
		y = (0.5 * (openfl.Lib.current.stage.stageHeight - _height * _defaultScale));
	}
}
