package window.components;

import flixel.util.FlxColor;
import openfl.display.Shape;
import openfl.geom.ColorTransform;
import openfl.text.TextField;
import openfl.text.TextFormat;

// TODO: Add proper scaling and max and min values (possible idea: getter and setter of progress which adjusts the targetScale using some hacky formula with % dunno)
class Slider extends ExSprite
{
	public var initialY:Float = 0;

	private var targetY:Float = 0;
	private var targetSY:Float = 0;
	private var targetSAlpha:Float = 1;
	private var accumTimer:Float = 0;

	private var _bgBar:Shape;
	private var _fgBar:Shape;
	private var _stepper:Shape;
	private var _stpText:TextField;

	private var _width:Int = 0;
	private var _height:Int = 0;

	public var bgColor(default, set):FlxColor = FlxColor.WHITE;

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

	public var progress:Float = 1;

	override public function new(width:Int = 100, height:Int = 5)
	{
		_width = width;
		_height = height;
		active = false; // cuz we manually update it

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

		_stpText = new TextField();
		_stpText.defaultTextFormat = new TextFormat(getFont('open_sans.ttf').fontName, 8, 0xFFFFFF);
		_stpText.defaultTextFormat.align = CENTER;
		_stpText.selectable = false;
		_stpText.embedFonts = true;
		_stpText.text = '100%';
		_stpText.x = _stepper.x - (_stepper.width * 0.5);
		_stpText.y = _stepper.y - (_stepper.height - 15);

		addChild(_bgBar);
		addChild(_fgBar);
		addChild(_stepper);
		addChild(_stpText);
	}

	override function update(elapsed:Float, deltaTime:Float)
	{
		var lerpVal:Float = flixel.math.FlxMath.bound(1 - (elapsed * 7.315), 0, 1);

		lerpTrack(this, "y", targetY, lerpVal);
		lerpTrack(_fgBar, "scaleX", progress, lerpVal);

		lerpTrack(_stpText, "y", targetSY, lerpVal);
		lerpTrack(_stpText, "alpha", targetSAlpha, lerpVal);
		_stpText.text = '${Math.round(_fgBar.scaleX * 100)}%';

		// We want it to be instant snapping
		_stepper.x = (_fgBar.width - _stepper.width) + (_stepper.width * 0.5);
		_stepper.y = (_fgBar.height - _stepper.height) * 0.5;

		_stpText.x = _stepper.x + (_stepper.width - _stpText.textWidth) * 0.5;

		if (!StringTools.contains(_stpText.text, "0"))
		{
			targetSAlpha = 1;
			targetSY = _stepper.y + (_stepper.height - _stpText.textHeight) + 10;
			targetY = initialY;
			accumTimer = 0;
		}
		else
		{
			accumTimer += elapsed;

			if (accumTimer >= 1.5)
			{
				targetSAlpha = 0;
				targetSY = 0;
				targetY = initialY + (_stpText.textHeight * 0.5);
			}
		}
	}
}
