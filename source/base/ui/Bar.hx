package base.ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using flixel.util.FlxColorTransformUtil;

class Bar extends FlxSprite
{
	private var _bgBarBit(default, null):BitmapData;
	private var _bgBarRect(default, null):Rectangle;
	private var _zeroOffset(default, null):Point;

	private var _fgBarBit(default, null):BitmapData;
	private var _fgBarRect(default, null):Rectangle;
	private var _fgBarPoint(default, null):Point;

	private var barWidth(default, null):Int;
	private var barHeight(default, null):Int;

	public var percent(get, null):Float = 0;

	@:noCompletion
	// Tested on the time bar, it was songPosition / length so it would give actual percentage
	// To get a good percentage, the value should be set as targetValue / max so it works
	private function get_percent():Float
		return Math.floor(value * 100);

	public var value:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, Width:Int = 100, Height:Int = 10, bgColor:FlxColor, fgColor:FlxColor)
	{
		super(x, y);

		this.barWidth = Width;
		this.barHeight = Height;

		_bgBarRect = new Rectangle();
		_zeroOffset = new Point();

		_fgBarRect = new Rectangle();
		_fgBarPoint = new Point();

		_bgBarBit = new BitmapData(barWidth, barHeight, true, bgColor);
		_bgBarRect.setTo(0, 0, barWidth, barHeight);
		_fgBarBit = new BitmapData(barWidth, barHeight, true, fgColor);
		_fgBarRect.setTo(0, 0, barWidth, barHeight);

		makeGraphic(Width, Height, FlxColor.TRANSPARENT, true);
	}

	override function destroy()
	{
		_bgBarBit = null;
		_bgBarRect = null;
		_zeroOffset = null;

		_fgBarBit = null;
		_fgBarRect = null;
		_fgBarRect = null;

		super.destroy();
	}

	override function draw()
	{
		pixels.copyPixels(_bgBarBit, _bgBarRect, _zeroOffset);

		_fgBarRect.width = (value * barWidth);
		_fgBarRect.height = barHeight;

		pixels.copyPixels(_fgBarBit, _fgBarRect, _fgBarPoint, null, null, true);

		super.draw();
	}
}
