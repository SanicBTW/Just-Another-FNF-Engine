package base.sprites;

import backend.Cache;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;

// Sanco Bar, basically an alternative to FlxBar but uhhhhhhhhhh better I guess???
// Originally from https://github.com/SanicBTW/Just-Another-FNF-Engine/blob/221672cfcc8e77ab1db4b5a11e23b14e642425a2/source/base/ui/Bar.hx
// Also fun fact, I made it after learning how FlxText worked
// i only copied the old code and added some funky color change lol
// TODO: proper getters and setters yknow what i mean
class SBar extends FlxSprite
{
	private var _bgBitmap(default, null):BitmapData;
	private var _bgRect(default, null):Rectangle;
	private var _bgPoint(default, null):Point;

	public var bgColor(default, set):FlxColor = FlxColor.GRAY;

	@:noCompletion
	private function set_bgColor(newColor:FlxColor):FlxColor
	{
		if (bgColor != newColor)
		{
			var colorTransform:ColorTransform = new ColorTransform();
			colorTransform.color = newColor;

			// this uses a rectangle as parameter to replace pixels inside the rectangle area, should have this in mind for the future
			_bgBitmap.colorTransform(_bgRect, colorTransform);
		}

		return bgColor = newColor;
	}

	private var _fgBitmap(default, null):BitmapData;
	private var _fgRect(default, null):Rectangle;
	private var _fgPoint(default, null):Point;

	public var fgColor(default, set):FlxColor = FlxColor.BLACK;

	@:noCompletion
	private function set_fgColor(newColor:FlxColor):FlxColor
	{
		if (fgColor != newColor)
		{
			var colorTransform:ColorTransform = new ColorTransform();
			colorTransform.color = newColor;

			_fgBitmap.colorTransform(_fgRect, colorTransform);
		}

		return fgColor = newColor;
	}

	// These should modify the sizes of the bar and sprite, the rectangles and shit yknow
	private var barWidth(default, null):Int;
	private var barHeight(default, null):Int;

	public var fillAxis:SBarFillAxis = HORIZONTAL;
	public var value:Float = 0;
	public var percent(get, null):Float = 0;

	@:noCompletion
	// Tested on the time bar, it was songPosition / length so it would give actual percentage
	// To get a good percentage, the value should be set as targetValue / max so it works
	// Ok it was actually the current width/height of the fg rect which represents the current bar progress divided by the full width/height of the sprite
	private function get_percent():Float
	{
		var max:Int = switch (fillAxis)
		{
			case HORIZONTAL: barWidth;
			case VERTICAL: barHeight;
		};

		var progress:Float = switch (fillAxis)
		{
			case HORIZONTAL: _fgRect.width;
			case VERTICAL: _fgRect.height;
		}

		return (progress / max);
	}

	public function new(X:Float = 0, Y:Float = 0, Width:Int = 100, Height:Int = 10, bgColor:FlxColor, fgColor:FlxColor)
	{
		super(X, Y);

		this.barWidth = Width;
		this.barHeight = Height;

		_bgRect = _fgRect = new Rectangle(0, 0, barWidth, barHeight);
		_bgPoint = _fgPoint = new Point();

		// Better naming to avoid reusing other bitmaps
		// my dumb ass forgot about setting fill collors bruhh - thought i fixed it (HTML5) guess fucking not - ithink html5 doesnt like lerps on fucking rectangles??
		_bgBitmap = Cache.set(new BitmapData(barWidth, barHeight, true, bgColor), BITMAP, 'SBAR_BG:${barWidth}x${barHeight}(${bgColor.toWebString()})');
		_fgBitmap = Cache.set(new BitmapData(barWidth, barHeight, true, fgColor), BITMAP, 'SBAR_FG:${barWidth}x${barHeight}(${fgColor.toWebString()})');

		// Setting it to false would cause the sprite to reuse another graphic with the same properties
		makeGraphic(barWidth, barHeight, FlxColor.TRANSPARENT, true);

		this.bgColor = bgColor;
		this.fgColor = fgColor;
	}

	override function destroy()
	{
		Cache.removeBitmapData('SBAR_BG:${barWidth}x${barHeight}(${bgColor.toWebString()})');
		Cache.removeBitmapData('SBAR_FG:${barWidth}x${barHeight}(${fgColor.toWebString()})');

		_bgRect = _fgRect = null;
		_bgPoint = _fgPoint = null;

		super.destroy();
	}

	// Should I modify the size of the bg rect too??? just in case it changes or some shit, nah i gotta work on them setters bruh
	override function draw()
	{
		pixels.copyPixels(_bgBitmap, _bgRect, _bgPoint);

		switch (fillAxis)
		{
			case HORIZONTAL:
				_fgRect.width = (value * barWidth);
				_fgRect.height = barHeight;
			case VERTICAL:
				_fgRect.width = barWidth;
				_fgRect.height = (value * barHeight);
		}

		pixels.copyPixels(_fgBitmap, _fgRect, _fgPoint, null, null, true);

		super.draw();
	}
}

enum SBarFillAxis
{
	HORIZONTAL;
	VERTICAL;
}
