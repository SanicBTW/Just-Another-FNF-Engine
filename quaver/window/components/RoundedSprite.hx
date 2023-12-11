package window.components;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import lime.math.Vector2;
import openfl.display.GraphicsPath;
import openfl.display.Shape;

typedef SetDataFunc = (type:Int, initIndex:Int, ?lerp:Float, data:haxe.Rest<Float>) -> Void;

// idk why i made it as an abstract enum lmfao, probably to remember about the command ints just in case
enum abstract CommandType(Int) to Int
{
	var MoveTo = 1;
	var LineTo = 2;
	var CurveTo = 3;
}

enum DrawMethod
{
	GRAPHICS_PATH; // Uses GraphicsPath
	SHAPE_DRAWING; // Uses Shape.drawRoundRectComplex every resize
}

// smart ass math(no)
// bro this ugly ass copy paste code i gotta make it better - i did make it better

class RoundedSprite extends Shape
{
	public static var drawMethod:DrawMethod = #if !html5 GRAPHICS_PATH #else SHAPE_DRAWING #end;

	static final anchor:Float = (1 - Math.sin(45 * (Math.PI / 180)));
	static final control:Float = (1 - Math.tan(22.5 * (Math.PI / 180)));
	// dumb fix for the weird drawing at 0 width/height
	static final min:Float = 3; // 1 and 2 kinda weird, imma go with 3 prob

	private var X:Float = 0;
	private var Y:Float = 0;
	private var Alpha:Float = 0;
	private var Path:GraphicsPath;
	private var Dirty:Bool = true;

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

		switch (drawMethod)
		{
			case GRAPHICS_PATH:
				Path = new GraphicsPath(new openfl.Vector<Int>(), new openfl.Vector<Float>(), NON_ZERO);
				_initGraphicsPath((X + Width), (Y + Height));
			case SHAPE_DRAWING:
				_redrawShape(Width, Height);
		}

		redraw();
	}

	// smartass cleaning and optimization
	public function setSize(newWidth:Float, newHeight:Float, ?lerp:Float)
	{
		Dirty = (newWidth != width || newHeight != height);

		// if the corners are lerped why the real size shouldnt
		if (lerp != null)
		{
			RealSizes.x = FlxMath.lerp(newWidth, RealSizes.x, lerp);
			RealSizes.y = FlxMath.lerp(newHeight, RealSizes.y, lerp);
		}
		else
			RealSizes.setTo(newWidth, newHeight);

		switch (drawMethod)
		{
			case GRAPHICS_PATH:
				_resizeGraphicsPath(newWidth, newHeight, lerp);
			case SHAPE_DRAWING: // nada
		}

		redraw();
	}

	public function redraw()
	{
		if (!Dirty)
			return;

		switch (drawMethod)
		{
			case GRAPHICS_PATH:
				graphics.clear();
				graphics.beginFill(Color, Alpha); // Fill color
				graphics.drawPath(Path.commands, Path.data, Path.winding);
				graphics.endFill();
			case SHAPE_DRAWING:
				// smartass shit
				graphics.clear();
				_redrawShape(RealSizes.x, RealSizes.y);
		}

		Dirty = false;
	}

	/// Init needed systems

	@:noCompletion
	private function _initGraphicsPath(XW:Float, YH:Float)
	{
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

		Dirty = true;
	}

	@:noCompletion
	private function _redrawShape(Width:Float, Height:Float)
	{
		graphics.beginFill(Color, Alpha);
		if (CornerRadius.length < 3)
			graphics.drawRoundRect(X, Y, Width, Height, CornerRadius[0], CornerRadius[0]);
		else
			graphics.drawRoundRectComplex(X, Y, Width, Height, CornerRadius[0], CornerRadius[1], CornerRadius[2], CornerRadius[3]);
		graphics.endFill();

		Dirty = true;
	}

	// Size systems

	@:noCompletion
	private function _resizeGraphicsPath(newWidth:Float, newHeight:Float, ?lerp:Float)
	{
		// Update the path data with the new size while preserving the corner radius
		var XW:Float = (X + newWidth);
		if (XW <= min)
			XW = min;

		var YH:Float = (Y + newHeight);
		if (YH <= min)
			YH = min;

		var callee:SetDataFunc = Reflect.field(this, lerp != null ? "setLerpData" : "setData");

		if (CornerRadius.length < 3)
		{
			var RAD:Float = (CornerRadius[0] / 2);
			var A:Float = RAD * anchor;
			var S:Float = RAD * control;

			// bottom right
			callee(MoveTo, 0, lerp, XW, YH - RAD);
			callee(CurveTo, 2, lerp, XW, YH - S, XW - A, YH - A);
			callee(CurveTo, 6, lerp, XW - S, YH, XW - RAD, YH);

			// bottom left
			callee(LineTo, 10, lerp, X + RAD, YH);
			callee(CurveTo, 12, lerp, X + S, YH, X + A, YH - A);
			callee(CurveTo, 16, lerp, X, YH - S, X, YH - RAD);

			// top left
			callee(LineTo, 20, lerp, X, Y + RAD);
			callee(CurveTo, 22, lerp, X, Y + S, X + A, Y + A);
			callee(CurveTo, 26, lerp, X + S, Y, X + RAD, Y);

			// top right
			callee(LineTo, 30, lerp, XW - RAD, Y);
			callee(CurveTo, 32, lerp, XW - S, Y, XW - A, Y + A);
			callee(CurveTo, 36, lerp, XW, Y + S, XW, Y + RAD);
			callee(LineTo, 40, lerp, XW, YH - RAD);
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
			callee(MoveTo, 0, lerp, XW, YH - BotRight_RAD);
			callee(CurveTo, 2, lerp, XW, YH - S, XW - A, YH - A);
			callee(CurveTo, 6, lerp, XW - S, YH, XW - BotRight_RAD, YH);

			A = BotLeft_RAD * anchor;
			S = BotLeft_RAD * control;

			// bottom left
			callee(LineTo, 10, lerp, X + BotLeft_RAD, YH);
			callee(CurveTo, 12, lerp, X + S, YH, X + A, YH - A);
			callee(CurveTo, 16, lerp, X, YH - S, X, YH - BotLeft_RAD);

			A = TopLeft_RAD * anchor;
			S = TopLeft_RAD * control;

			// top left
			callee(LineTo, 20, lerp, X, Y + TopLeft_RAD);
			callee(CurveTo, 22, lerp, X, Y + S, X + A, Y + A);
			callee(CurveTo, 26, lerp, X + S, Y, X + TopLeft_RAD, Y);

			A = TopRight_RAD * anchor;
			S = TopRight_RAD * control;

			// top right
			callee(LineTo, 30, lerp, XW - TopRight_RAD, Y);
			callee(CurveTo, 32, lerp, XW - S, Y, XW - A, Y + A);
			callee(CurveTo, 36, lerp, XW, Y + S, XW, Y + TopRight_RAD);
			callee(LineTo, 40, lerp, XW, YH - TopRight_RAD);
		}

		Dirty = true;
	}

	/// Helpers

	@:noCompletion
	private function setData(type:CommandType = CommandType.LineTo, initIndex:Int, data:haxe.Rest<Float>)
	{
		var arr:Array<Float> = data.toArray();
		switch (type)
		{
			// Move to and line to only takes up 2 indices of GraphicsPath data
			case MoveTo | LineTo:
				{
					Path.data[initIndex] = arr[0];
					Path.data[initIndex + 1] = arr[1];
				}

			// Curve to takes up to 3 indices or 4 indices including the init
			case CurveTo:
				{
					Path.data[initIndex] = arr[0];
					Path.data[initIndex + 1] = arr[1];
					Path.data[initIndex + 2] = arr[2];
					Path.data[initIndex + 3] = arr[3];
				}
		}
	}

	@:noCompletion
	private function setLerpData(type:CommandType = CommandType.LineTo, initIndex:Int, lerp:Float, data:haxe.Rest<Float>)
	{
		var arr:Array<Float> = data.toArray();
		switch (type)
		{
			// Move to and line to only takes up 2 indices of GraphicsPath data
			case MoveTo | LineTo:
				{
					Path.data[initIndex] = FlxMath.lerp(arr[0], Path.data[initIndex], lerp);
					Path.data[initIndex + 1] = FlxMath.lerp(arr[1], Path.data[initIndex + 1], lerp);
				}

			// Curve to takes up to 3 indices or 4 indices including the init
			case CurveTo:
				{
					Path.data[initIndex] = FlxMath.lerp(arr[0], Path.data[initIndex], lerp);
					Path.data[initIndex + 1] = FlxMath.lerp(arr[1], Path.data[initIndex + 1], lerp);
					Path.data[initIndex + 2] = FlxMath.lerp(arr[2], Path.data[initIndex + 2], lerp);
					Path.data[initIndex + 3] = FlxMath.lerp(arr[3], Path.data[initIndex + 3], lerp);
				}
		}
	}
}
