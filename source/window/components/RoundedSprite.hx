package window.components;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import lime.math.Vector2;
import openfl.display.Shape;

// Forced draw method to Shape drawing since it seems more efficient but memory allocation exhausting, at least now i can work on both targets without having to mess up the other one
// When hiding or making the sprite not visible clean the generated bitmaps atm
class RoundedSprite extends Shape
{
	private var X:Float = 0;
	private var Y:Float = 0;

	private var Dirty:Bool = true;

	public var CornerRadius:Array<Float> = [];
	public var Color:FlxColor = FlxColor.WHITE;
	public var RealSizes:Vector2 = new Vector2(0, 0);
	public var ForceResize:Bool = false; // i want to kms

	public function new(X:Float, Y:Float, Width:Float, Height:Float, CornerRadius:Array<Float>, Color:FlxColor = FlxColor.WHITE, Alpha:Float = 1)
	{
		super();

		this.X = X;
		this.Y = Y;
		this.RealSizes.setTo(Width, Height);

		this.Color = Color;
		this.alpha = Alpha;

		this.CornerRadius = CornerRadius;

		_redrawShape(Width, Height);

		redraw();
	}

	// smartass cleaning and optimization
	public function setSize(newWidth:Float, newHeight:Float, lerp:Float = 1)
	{
		var oldWidth:Int = Math.ceil(RealSizes.x);
		var oldHeight:Int = Math.ceil(RealSizes.y);

		var newIWidth:Int = Math.ceil(newWidth);
		var newIHeight:Int = Math.ceil(newHeight);

		if ((newIWidth > oldWidth || newIHeight > oldHeight) || ForceResize)
		{
			// if the corners are lerped why the real size shouldnt
			RealSizes.x = FlxMath.lerp(newWidth, RealSizes.x, lerp);
			RealSizes.y = FlxMath.lerp(newHeight, RealSizes.y, lerp);

			Dirty = true;

			redraw();
		}
	}

	public function redraw()
	{
		if (!Dirty)
			return;

		// smartass shit
		graphics.clear();
		_redrawShape(RealSizes.x, RealSizes.y);

		Dirty = false;
	}

	@:noCompletion
	private function _redrawShape(Width:Float, Height:Float)
	{
		graphics.beginFill(Color, alpha);
		if (CornerRadius.length < 3)
			graphics.drawRoundRect(X, Y, Width, Height, CornerRadius[0], CornerRadius[0]);
		else
			graphics.drawRoundRectComplex(X, Y, Width, Height, CornerRadius[0], CornerRadius[1], CornerRadius[2], CornerRadius[3]);
		graphics.endFill();

		Dirty = true;
	}
}
