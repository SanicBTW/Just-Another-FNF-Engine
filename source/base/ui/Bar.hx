package base.ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

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

	public var value:Float = 0;

	public function new(x:Float = 0, y:Float = 0, width:Int = 100, height:Int = 10, bgColor:FlxColor, fgColor:FlxColor)
	{
		super(x, y);

		this.barWidth = width;
		this.barHeight = height;

		_bgBarRect = new Rectangle();
		_zeroOffset = new Point();

		_fgBarRect = new Rectangle();
		_fgBarPoint = new Point();

		_bgBarBit = Cache.setBitmap("bgBarBitmap", new BitmapData(barWidth, barHeight, true, bgColor));
		_bgBarRect.setTo(0, 0, barWidth, barHeight);

		_fgBarBit = Cache.setBitmap("fgBarBitmap", new BitmapData(barWidth, barHeight, true, fgColor));
		_fgBarRect.setTo(0, 0, barWidth, barHeight);

		makeGraphic(width, height, FlxColor.TRANSPARENT, true);
	}

	override public function destroy()
	{
		_bgBarBit = null;
		Cache.disposeBitmap("bgBarBitmap");
		_bgBarRect = null;
		_zeroOffset = null;

		_fgBarBit = null;
		Cache.disposeBitmap("fgBarBitmap");
		_fgBarRect = null;
		_fgBarRect = null;

		super.destroy();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// update bg
		pixels.copyPixels(_bgBarBit, _bgBarRect, _zeroOffset);

		// update fg
		_fgBarRect.width = (value * barWidth);
		_fgBarRect.height = barHeight;

		pixels.copyPixels(_fgBarBit, _fgBarRect, _fgBarPoint, null, null, true);
	}
}
