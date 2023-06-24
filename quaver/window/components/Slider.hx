package window.components;

import flixel.util.FlxColor;
import openfl.display.Shape;
import openfl.geom.ColorTransform;

class Slider extends ExSprite
{
	private var _bgBar:Shape;
	private var _fgBar:Shape;
	private var _stepper:Shape;

	private var _width:Int = 0;
	private var _height:Int = 0;

	public var bgColor(default, set):FlxColor = FlxColor.GRAY;

	@:noCompletion
	private function set_bgColor(newColor:FlxColor)
	{
		if (bgColor != newColor)
		{
			var colorTransform:ColorTransform = new ColorTransform();
			colorTransform.color = newColor;

			_bgBar.transform.colorTransform = colorTransform;
		}

		return bgColor = newColor;
	}

	public var fgColor(default, set):FlxColor = FlxColor.BLACK;

	@:noCompletion
	private function set_fgColor(newColor:FlxColor)
	{
		if (fgColor != newColor)
		{
			var colorTransform:ColorTransform = new ColorTransform();
			colorTransform.color = newColor;

			_fgBar.transform.colorTransform = colorTransform;
		}

		return fgColor = newColor;
	}

	override public function new(width:Int = 100, height:Int = 5)
	{
		_width = width;
		_height = height;

		super();
	}

	override function create()
	{
		_bgBar = drawRound(0, 0, _width, _height, [_height], bgColor, 1);
		_fgBar = drawRound(0, 0, _width, _height, [_height], fgColor, 1);

		_stepper = drawRound(0, 0, _height + 5, _height + 5, [15], fgColor, 1);
		// start pos in case the lerp is too funky
		_stepper.x = (_fgBar.width - _stepper.width) + (_stepper.width * 0.5);
		_stepper.y = (_fgBar.height - _stepper.height) * 0.5;

		addChild(_bgBar);
		addChild(_fgBar);
		addChild(_stepper);
	}

	override function update(elapsed:Float, deltaTime:Float)
	{
		var lerpVal:Float = flixel.math.FlxMath.bound(1 - (elapsed * 7.315), 0, 1);

		lerpTrack(_stepper, "x", (_fgBar.width - _stepper.width) + (_stepper.width * 0.5), lerpVal);
		lerpTrack(_stepper, "y", (_fgBar.height - _stepper.height) * 0.5, lerpVal);
	}
}
