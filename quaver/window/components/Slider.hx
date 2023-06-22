package window.components;

import flixel.util.FlxColor;
import openfl.display.Shape;

class Slider extends ExSprite
{
	private var _bar:Shape;
	private var _stepper:Shape;

	private var _width:Int = 0;
	private var _height:Int = 0;

	override public function new(width:Int = 100, height:Int = 5)
	{
		_width = width;
		_height = height;

		super();
	}

	override public function create()
	{
		_bar = drawRound(0, 0, _width, _height, [_height], FlxColor.CYAN, 1);

		_stepper = drawRound(0, 0, _height + 5, _height + 5, [15], FlxColor.BLACK, 1);
		_stepper.x = (_bar.width - _stepper.width);
		_stepper.y = (_bar.height - _stepper.height) * 0.5;

		addChild(_bar);
		addChild(_stepper);
	}
}
