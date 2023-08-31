package window.components;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import lime.math.Vector2;
import openfl.display.GraphicsPath;
import openfl.display.Shape;

typedef SetDataFunc = (type:Int, initIndex:Int, ?lerp:Float, data:haxe.Rest<Float>) -> Void;

// smart ass math(no)
// bro this ugly ass copy paste code i gotta make it better - i did make it better

class RoundedSprite extends Shape
{
	static final anchor:Float = (1 - Math.sin(45 * (Math.PI / 180)));
	static final control:Float = (1 - Math.tan(22.5 * (Math.PI / 180)));
	// dumb fix for the weird drawing at 0 width/height
	static final min:Float = 3; // 1 and 2 kinda weird, imma go with 3 prob

	private var X:Float = 0;
	private var Y:Float = 0;
	private var Alpha:Float = 0;
	private var Path:GraphicsPath = new GraphicsPath();

	// another dumb fix because i cant get a good way of getting the real width by subtracting the min
	public var RealSizes:Vector2 = new Vector2(0, 0);
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
		this.RealSizes.setTo(Width, Height);

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

	// smartass cleaning and optimization
	public function setSize(newWidth:Float, newHeight:Float, ?lerp:Float)
	{
		// Update the path data with the new size while preserving the corner radius
		var XW:Float = (X + newWidth);
		if (XW <= min)
			XW = min;

		var YH:Float = (Y + newHeight);
		if (YH <= min)
			YH = min;

		var callee:SetDataFunc = Reflect.field(this, lerp != null ? "setLerpData" : "setData");

		// if the corners are lerped why the real size shouldnt
		if (lerp != null)
		{
			RealSizes.x = FlxMath.lerp(newWidth, RealSizes.x, lerp);
			RealSizes.y = FlxMath.lerp(newHeight, RealSizes.y, lerp);
		}
		else
			RealSizes.setTo(newWidth, newHeight);

		if (CornerRadius.length < 3)
		{
			var RAD:Float = (CornerRadius[0] / 2);
			var A:Float = RAD * anchor;
			var S:Float = RAD * control;

			// bottom right
			callee(1, 0, lerp, XW, YH - RAD);
			callee(3, 2, lerp, XW, YH - S, XW - A, YH - A);
			callee(3, 6, lerp, XW - S, YH, XW - RAD, YH);

			// bottom left
			callee(2, 10, lerp, X + RAD, YH);
			callee(3, 12, lerp, X + S, YH, X + A, YH - A);
			callee(3, 16, lerp, X, YH - S, X, YH - RAD);

			// top left
			callee(2, 20, lerp, X, Y + RAD);
			callee(3, 22, lerp, X, Y + S, X + A, Y + A);
			callee(3, 26, lerp, X + S, Y, X + RAD, Y);

			// top right
			callee(2, 30, lerp, XW - RAD, Y);
			callee(3, 32, lerp, XW - S, Y, XW - A, Y + A);
			callee(3, 36, lerp, XW, Y + S, XW, Y + RAD);
			callee(2, 40, lerp, XW, YH - RAD);
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
			callee(1, 0, lerp, XW, YH - BotRight_RAD);
			callee(3, 2, lerp, XW, YH - S, XW - A, YH - A);
			callee(3, 6, lerp, XW - S, YH, XW - BotRight_RAD, YH);

			A = BotLeft_RAD * anchor;
			S = BotLeft_RAD * control;

			// bottom left
			callee(2, 10, lerp, X + BotLeft_RAD, YH);
			callee(3, 12, lerp, X + S, YH, X + A, YH - A);
			callee(3, 16, lerp, X, YH - S, X, YH - BotLeft_RAD);

			A = TopLeft_RAD * anchor;
			S = TopLeft_RAD * control;

			// top left
			callee(2, 20, lerp, X, Y + TopLeft_RAD);
			callee(3, 22, lerp, X, Y + S, X + A, Y + A);
			callee(3, 26, lerp, X + S, Y, X + TopLeft_RAD, Y);

			A = TopRight_RAD * anchor;
			S = TopRight_RAD * control;

			// top right
			callee(2, 30, lerp, XW - TopRight_RAD, Y);
			callee(3, 32, lerp, XW - S, Y, XW - A, Y + A);
			callee(3, 36, lerp, XW, Y + S, XW, Y + TopRight_RAD);
			callee(2, 40, lerp, XW, YH - TopRight_RAD);
		}

		redraw();
	}

	public function redraw()
	{
		graphics.clear();
		graphics.beginFill(Color, Alpha); // Fill color
		graphics.drawPath(Path.commands, Path.data, Path.winding);
		graphics.endFill();
	}

	/*
		Types
		- MoveTo - 1
		- LineTo - 2
		- CurveTo - 3
	 */
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
	private function setLerpData(type:Int = 1, initIndex:Int, lerp:Float, data:haxe.Rest<Float>)
	{
		var arr:Array<Float> = data.toArray();
		switch (type)
		{
			// Move to and line to only takes up 2 indices of GraphicsPath data
			case 1 | 2:
				{
					Path.data[initIndex] = FlxMath.lerp(arr[0], Path.data[initIndex], lerp);
					Path.data[initIndex + 1] = FlxMath.lerp(arr[1], Path.data[initIndex + 1], lerp);
				}

			// Curve to takes up to 3 indices or 4 indices including the init
			case 3:
				{
					Path.data[initIndex] = FlxMath.lerp(arr[0], Path.data[initIndex], lerp);
					Path.data[initIndex + 1] = FlxMath.lerp(arr[1], Path.data[initIndex + 1], lerp);
					Path.data[initIndex + 2] = FlxMath.lerp(arr[2], Path.data[initIndex + 2], lerp);
					Path.data[initIndex + 3] = FlxMath.lerp(arr[3], Path.data[initIndex + 3], lerp);
				}
		}
	}
}
