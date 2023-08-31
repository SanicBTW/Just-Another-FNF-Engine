package window.components;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.GraphicsPath;
import openfl.display.Shape;

// smart ass math(no)
// bro this ugly ass copy paste code i gotta make it better
// gotta avoid having 0 sizes cuz it looks weird
class RoundedSprite extends Shape
{
	static final anchor:Float = (1 - Math.sin(45 * (Math.PI / 180)));
	static final control:Float = (1 - Math.tan(22.5 * (Math.PI / 180)));

	private var X:Float = 0;
	private var Y:Float = 0;
	private var Alpha:Float = 0;
	private var Path:GraphicsPath = new GraphicsPath();

	public var CornerRadius:Array<Float> = [];
	public var Color:FlxColor = FlxColor.WHITE;

	public function new(X:Float, Y:Float, Width:Float, Height:Float, CornerRadius:Array<Float>, Color:FlxColor = FlxColor.WHITE, Alpha:Float = 1)
	{
		super();

		this.X = X;
		this.Y = Y;
		this.CornerRadius = CornerRadius;
		this.Color = Color;
		this.Alpha = Alpha;

		var XW:Float = (X + Width);
		var YH:Float = (Y + Height);

		if (CornerRadius.length < 3)
		{
			// See Graphics.drawRoundRectComplex
			var RAD:Float = (CornerRadius[0] / 2);

			var A:Float = RAD * anchor;
			var S:Float = RAD * control;

			// bottom right
			Path.moveTo(XW, YH - RAD);
			Path.curveTo(XW, YH - S, XW - A, YH - A);
			Path.curveTo(XW - S, YH, XW - RAD, YH);

			// bottom left
			Path.lineTo(X + RAD, YH);
			Path.curveTo(X + S, YH, X + A, YH - A);
			Path.curveTo(X, YH - S, X, YH - RAD);

			// top left
			Path.lineTo(X, Y + RAD);
			Path.curveTo(X, Y + S, X + A, Y + A);
			Path.curveTo(X + S, Y, X + RAD, Y);

			// top right
			Path.lineTo(XW - RAD, Y);
			Path.curveTo(XW - S, Y, XW - A, Y + A);
			Path.curveTo(XW, Y + S, XW, Y + RAD);
			Path.lineTo(XW, YH - RAD);
		}
		else
		{
			var TopLeft_RAD:Float = (CornerRadius[0] / 2);
			var TopRight_RAD:Float = (CornerRadius[1] / 2);
			var BotLeft_RAD:Float = (CornerRadius[2] / 2);
			var BotRight_RAD:Float = (CornerRadius[3] / 2);

			var A:Float = BotRight_RAD * anchor;
			var S:Float = BotRight_RAD * control;

			// bottom right
			Path.moveTo(XW, YH - BotRight_RAD);
			Path.curveTo(XW, YH - S, XW - A, YH - A);
			Path.curveTo(XW - S, YH, XW - BotRight_RAD, YH);

			A = BotLeft_RAD * anchor;
			S = BotLeft_RAD * control;

			// bottom left
			Path.lineTo(X + BotLeft_RAD, YH);
			Path.curveTo(X + S, YH, X + A, YH - A);
			Path.curveTo(X, YH - S, X, YH - BotLeft_RAD);

			A = TopLeft_RAD * anchor;
			S = TopLeft_RAD * control;

			// top left
			Path.lineTo(X, Y + TopLeft_RAD);
			Path.curveTo(X, Y + S, X + A, Y + A);
			Path.curveTo(X + S, Y, X + TopLeft_RAD, Y);

			A = TopRight_RAD * anchor;
			S = TopRight_RAD * control;

			// top right
			Path.lineTo(XW - TopRight_RAD, Y);
			Path.curveTo(XW - S, Y, XW - A, Y + A);
			Path.curveTo(XW, Y + S, XW, Y + TopRight_RAD);
			Path.lineTo(XW, YH - TopRight_RAD);
		}

		redraw();
	}

	public function setSize(newWidth:Float, ?newHeight:Float)
	{
		// Update the path data with the new size while preserving the corner radius
		var XW:Float = (X + newWidth);
		var YH:Float = (Y + newHeight);

		if (CornerRadius.length < 3)
		{
			var RAD:Float = (CornerRadius[0] / 2);
			var A:Float = RAD * anchor;
			var S:Float = RAD * control;

			// bottom right
			setData(1, 0, XW, YH - RAD);
			setData(3, 2, XW, YH - S, XW - A, YH - A);
			setData(3, 6, XW - S, YH, XW - RAD, YH);

			// bottom left
			setData(2, 10, X + RAD, YH);
			setData(3, 12, X + S, YH, X + A, YH - A);
			setData(3, 16, X, YH - S, X, YH - RAD);

			// top left
			setData(2, 20, X, Y + RAD);
			setData(3, 22, X, Y + S, X + A, Y + A);
			setData(3, 26, X + S, Y, X + RAD, Y);

			// top right
			setData(2, 30, XW - RAD, Y);
			setData(3, 32, XW - S, Y, XW - A, Y + A);
			setData(3, 36, XW, Y + S, XW, Y + RAD);
			setData(2, 40, XW, YH - RAD);
		}
		else
		{
			var TopLeft_RAD:Float = (CornerRadius[0] / 2);
			var TopRight_RAD:Float = (CornerRadius[1] / 2);
			var BotLeft_RAD:Float = (CornerRadius[2] / 2);
			var BotRight_RAD:Float = (CornerRadius[3] / 2);

			var A:Float = BotRight_RAD * anchor;
			var S:Float = BotRight_RAD * control;

			// bottom right
			setData(1, 0, XW, YH - BotRight_RAD);
			setData(3, 2, XW, YH - S, XW - A, YH - A);
			setData(3, 6, XW - S, YH, XW - BotRight_RAD, YH);

			A = BotLeft_RAD * anchor;
			S = BotLeft_RAD * control;

			// bottom left
			setData(2, 10, X + BotLeft_RAD, YH);
			setData(3, 12, X + S, YH, X + A, YH - A);
			setData(3, 16, X, YH - S, X, YH - BotLeft_RAD);

			A = TopLeft_RAD * anchor;
			S = TopLeft_RAD * control;

			// top left
			setData(2, 20, X, Y + TopLeft_RAD);
			setData(3, 22, X, Y + S, X + A, Y + A);
			setData(3, 26, X + S, Y, X + TopLeft_RAD, Y);

			A = TopRight_RAD * anchor;
			S = TopRight_RAD * control;

			// top right
			setData(2, 30, XW - TopRight_RAD, Y);
			setData(3, 32, XW - S, Y, XW - A, Y + A);
			setData(3, 36, XW, Y + S, XW, Y + TopRight_RAD);
			setData(2, 40, XW, YH - TopRight_RAD);
		}

		redraw();
	}

	// Just setSize but with lerping
	public function smoothSetSize(newWidth:Float, newHeight:Float, ratio:Float)
	{
		// Update the path data with the new size while preserving the corner radius
		var XW:Float = (X + newWidth);
		var YH:Float = (Y + newHeight);

		if (CornerRadius.length < 3)
		{
			var RAD:Float = (CornerRadius[0] / 2);
			var A:Float = RAD * anchor;
			var S:Float = RAD * control;

			// bottom right
			setLerpData(1, 0, ratio, XW, YH - RAD);
			setLerpData(3, 2, ratio, XW, YH - S, XW - A, YH - A);
			setLerpData(3, 6, ratio, XW - S, YH, XW - RAD, YH);

			// bottom left
			setLerpData(2, 10, ratio, X + RAD, YH);
			setLerpData(3, 12, ratio, X + S, YH, X + A, YH - A);
			setLerpData(3, 16, ratio, X, YH - S, X, YH - RAD);

			// top left
			setLerpData(2, 20, ratio, X, Y + RAD);
			setLerpData(3, 22, ratio, X, Y + S, X + A, Y + A);
			setLerpData(3, 26, ratio, X + S, Y, X + RAD, Y);

			// top right
			setLerpData(2, 30, ratio, XW - RAD, Y);
			setLerpData(3, 32, ratio, XW - S, Y, XW - A, Y + A);
			setLerpData(3, 36, ratio, XW, Y + S, XW, Y + RAD);
			setLerpData(2, 40, ratio, XW, YH - RAD);
		}
		else
		{
			var TopLeft_RAD:Float = (CornerRadius[0] / 2);
			var TopRight_RAD:Float = (CornerRadius[1] / 2);
			var BotLeft_RAD:Float = (CornerRadius[2] / 2);
			var BotRight_RAD:Float = (CornerRadius[3] / 2);

			var A:Float = BotRight_RAD * anchor;
			var S:Float = BotRight_RAD * control;

			// bottom right
			setLerpData(1, 0, ratio, XW, YH - BotRight_RAD);
			setLerpData(3, 2, ratio, XW, YH - S, XW - A, YH - A);
			setLerpData(3, 6, ratio, XW - S, YH, XW - BotRight_RAD, YH);

			A = BotLeft_RAD * anchor;
			S = BotLeft_RAD * control;

			// bottom left
			setLerpData(2, 10, ratio, X + BotLeft_RAD, YH);
			setLerpData(3, 12, ratio, X + S, YH, X + A, YH - A);
			setLerpData(3, 16, ratio, X, YH - S, X, YH - BotLeft_RAD);

			A = TopLeft_RAD * anchor;
			S = TopLeft_RAD * control;

			// top left
			setLerpData(2, 20, ratio, X, Y + TopLeft_RAD);
			setLerpData(3, 22, ratio, X, Y + S, X + A, Y + A);
			setLerpData(3, 26, ratio, X + S, Y, X + TopLeft_RAD, Y);

			A = TopRight_RAD * anchor;
			S = TopRight_RAD * control;

			// top right
			setLerpData(2, 30, ratio, XW - TopRight_RAD, Y);
			setLerpData(3, 32, ratio, XW - S, Y, XW - A, Y + A);
			setLerpData(3, 36, ratio, XW, Y + S, XW, Y + TopRight_RAD);
			setLerpData(2, 40, ratio, XW, YH - TopRight_RAD);
		}

		redraw();
	}

	public function redraw()
	{
		graphics.clear();
		graphics.beginFill(Color, Alpha); // Fill color
		graphics.drawPath(Path.commands, Path.data);
		graphics.endFill();
	}

	/// HELPERS I HAVE TO MAKE THEM BETTER FUCK

	/**
		Types
		- MoveTo - 1
		- LineTo - 2
		- CurveTo - 3
	**/
	// kind of a dumb helper to avoid having to clutter code with same code

	@:noCompletion
	private function setData(type:Int = 1, initIndex:Int, data:haxe.Rest<Float>)
	{
		var arr:Array<Float> = data.toArray();
		switch (type)
		{
			// Move to and line to only takes up 2 indices of GraphicsPath data
			case 1 | 2:
				{
					Path.data[initIndex] = arr[0];
					Path.data[initIndex + 1] = arr[1];
				}

			// Curve to takes up to 3 indices or 4 indices including the init
			case 3:
				{
					Path.data[initIndex] = arr[0];
					Path.data[initIndex + 1] = arr[1];
					Path.data[initIndex + 2] = arr[2];
					Path.data[initIndex + 3] = arr[3];
				}
		}
	}

	// kind of a dumb lerp helper to avoid having to clutter code with same code

	@:noCompletion
	private function setLerpData(type:Int = 1, initIndex:Int, ratio:Float, data:haxe.Rest<Float>)
	{
		var arr:Array<Float> = data.toArray();
		switch (type)
		{
			// Move to and line to only takes up 2 indices of GraphicsPath data
			case 1 | 2:
				{
					Path.data[initIndex] = FlxMath.lerp(arr[0], Path.data[initIndex], ratio);
					Path.data[initIndex + 1] = FlxMath.lerp(arr[1], Path.data[initIndex + 1], ratio);
				}

			// Curve to takes up to 3 indices or 4 indices including the init
			case 3:
				{
					Path.data[initIndex] = FlxMath.lerp(arr[0], Path.data[initIndex], ratio);
					Path.data[initIndex + 1] = FlxMath.lerp(arr[1], Path.data[initIndex + 1], ratio);
					Path.data[initIndex + 2] = FlxMath.lerp(arr[2], Path.data[initIndex + 2], ratio);
					Path.data[initIndex + 3] = FlxMath.lerp(arr[3], Path.data[initIndex + 3], ratio);
				}
		}
	}
}
