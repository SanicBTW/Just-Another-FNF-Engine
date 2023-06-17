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
	private var _outlineSize:Int = 5;

	private var targetX:Float = 0.0;
	private var targetY:Float = 0.0;

	private var _bg:Shape;
	private var _outline:Shape;

	override public function create()
	{
		_outline = drawRound(0, 0, _width + _outlineSize, _height + _outlineSize, [15], FlxColor.BLACK, 0.25);
		_bg = drawRound(_outlineSize * 0.5, _outlineSize * 0.5, _width, _height, [15], FlxColor.WHITE, 0.6);

		_width += _outlineSize;
		_height += _outlineSize;

		screenCenter();
		addChild(_outline);
		addChild(_bg);

		FlxG.signals.gameResized.add((w, h) ->
		{
			reposition(w, h);
		});
	}

	override function update(elapsed:Float, deltaTime:Float)
	{
		var lerpVal:Float = flixel.math.FlxMath.bound(1 - (elapsed * 7.315), 0, 1);

		lerpTrack(this, "x", targetX, lerpVal);
		lerpTrack(this, "y", targetY, lerpVal);
	}

	override function screenCenter()
	{
		scaleX = scaleY = _defaultScale;

		targetX = (0.5 * (openfl.Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
		targetY = (0.5 * (openfl.Lib.current.stage.stageHeight - _height * _defaultScale) - FlxG.game.y);
	}

	function reposition(newWidth:Float, newHeight:Float)
	{
		// cuz uh
		var margin:Float = (_outlineSize * 2);
		targetX = margin;
		targetY = (newHeight - (_height + _outline.height)) - margin;
	}
}