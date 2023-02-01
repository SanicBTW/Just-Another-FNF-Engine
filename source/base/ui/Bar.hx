package base.ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

// set bitmap shit to cache, follows the same scheme as flxbar but less full of shit- rewrite soon??? lmao
class Bar extends FlxSprite
{
	private var _bgBarBit:BitmapData;
	private var _bgBarRect:Rectangle;
	private var _zeroOffset:Point;

	private var _fgBarBit:BitmapData;
	private var _fgBarRect:Rectangle;
	private var _fgBarPoint:Point;

	private var barWidth(default, null):Int;
	private var barHeight(default, null):Int;

	public var range(default, null):Float = 0;
	public var max(default, null):Float = 0;
	public var min(default, null):Float = 0;

	public var value:Float = 0;

	public function new(x:Float = 0, y:Float = 0, width:Int = 100, height:Int = 10, max:Float = 100, min:Float = 0)
	{
		super(x, y);

		this.barWidth = width;
		this.barHeight = height;

		_bgBarRect = new Rectangle();
		_zeroOffset = new Point();

		_fgBarRect = new Rectangle();
		_fgBarPoint = new Point();

		_bgBarBit = new BitmapData(barWidth, barHeight, true, FlxColor.WHITE);
		_bgBarRect.setTo(0, 0, barWidth, barHeight);

		_fgBarBit = new BitmapData(barWidth, barHeight, true, FlxColor.BLACK);
		_fgBarRect.setTo(0, 0, barWidth, barHeight);

		makeGraphic(width, height, FlxColor.TRANSPARENT, true);

		setRange(max, min);
	}

	// use cache disposal
	override public function destroy()
	{
		_bgBarBit = null;
		_bgBarRect = null;
		_zeroOffset = null;

		_fgBarBit = null;
		_fgBarRect = null;
		_fgBarRect = null;

		super.destroy();
	}

	override public function update(elapsed:Float)
	{
		// update bg
		pixels.copyPixels(_bgBarBit, _bgBarRect, _zeroOffset);

		// update fg
		_fgBarRect.width = barWidth;
		_fgBarRect.height = barHeight;

		// _fgBarRect.width = (value * barWidth); // old format
		_fgBarRect.width = (((value - min) / range) * barWidth);

		pixels.copyPixels(_fgBarBit, _fgBarRect, _fgBarPoint, null, null, true);
	}

	public function setRange(max:Float, min:Float)
	{
		if (max <= min)
		{
			throw "Max cannot be less than or equal to min";
			return;
		}

		this.max = max;
		this.min = min;
		this.range = max - min;

		if (!Math.isNaN(value))
		{
			value = Math.max(min, Math.min(value, max));
		}
		else
			value = min;
	}
}
