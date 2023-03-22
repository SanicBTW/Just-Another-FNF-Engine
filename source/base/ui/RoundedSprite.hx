package base.ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil.DrawStyle;
import flixel.util.FlxSpriteUtil.LineStyle;
import openfl.display.Graphics;
import openfl.display.Sprite;

using flixel.util.FlxColorTransformUtil;

class RoundedSprite extends FlxSprite
{
	private static var gfxSprite(default, null):Sprite = new Sprite();
	private static var gfx(default, null):Graphics = gfxSprite.graphics;

	public var cornerSize(default, set):Float;

	private var Color:FlxColor;

	private function set_cornerSize(Value:Float):Float
	{
		if (cornerSize == Value)
			return Value;

		cornerSize = Value;

		drawRoundRect({thickness: 0, color: FlxColor.TRANSPARENT}, {smoothing: true});
		return Value;
	}

	override public function new(X:Float, Y:Float, Width:Float, Height:Float, Color:FlxColor, Radius:Float = 15)
	{
		super(X, Y);
		this.width = Width;
		this.height = Height;
		this.Color = Color;

		makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT, false);
		this.cornerSize = Radius;
		antialiasing = SaveData.antialiasing;
	}

	private function drawRoundRect(?lineStyle:LineStyle, ?drawStyle:DrawStyle)
	{
		beginDraw(Color, lineStyle);
		gfx.drawRoundRectComplex(x, y, width, height, cornerSize, cornerSize, cornerSize, cornerSize);
		endDraw(drawStyle);
	}

	private function beginDraw(FillColor:FlxColor, ?lineStyle:LineStyle)
	{
		gfx.clear();
		setLineStyle(lineStyle);

		if (FillColor != FlxColor.TRANSPARENT)
			gfx.beginFill(FillColor.to24Bit(), FillColor.alphaFloat);
	}

	private function endDraw(?drawStyle:DrawStyle)
	{
		if (drawStyle == null)
			drawStyle = {smoothing: false};
		else if (drawStyle.smoothing == null)
			drawStyle.smoothing = false;

		pixels.draw(gfxSprite, drawStyle.matrix, drawStyle.colorTransform, drawStyle.blendMode, drawStyle.clipRect, drawStyle.smoothing);
		dirty = true;
	}

	private function setLineStyle(lineStyle:LineStyle)
	{
		if (lineStyle != null)
		{
			var color = (lineStyle.color == null) ? FlxColor.BLACK : lineStyle.color;

			if (lineStyle.thickness == null)
				lineStyle.thickness = 1;
			if (lineStyle.pixelHinting == null)
				lineStyle.pixelHinting = false;
			if (lineStyle.miterLimit == null)
				lineStyle.miterLimit = 3;

			gfx.lineStyle(lineStyle.thickness, color.to24Bit(), color.alphaFloat, lineStyle.pixelHinting, lineStyle.scaleMode, lineStyle.capsStyle,
				lineStyle.jointStyle, lineStyle.miterLimit);
		}
	}
}
