package base.ui;

import flixel.FlxSprite;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil.DrawStyle;
import flixel.util.FlxSpriteUtil.LineStyle;

using flixel.util.FlxColorTransformUtil;

class CircularSprite extends FlxSprite
{
	private var Color:FlxColor;

	override public function new(X:Float, Y:Float, Width:Float, Height:Float, Color:FlxColor)
	{
		super(X, Y);
		this.width = Width;
		this.height = Height;
		this.Color = Color;

		makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT, false);
		drawStuff((x), -1, (x + width), -1, {thickness: 1, color: FlxColor.BLACK}, {smoothing: true});
	}

	private function drawStuff(dX:Float = -1, dY:Float = -1, d2X:Float = -1, d2Y:Float = -1, ?lineStyle:LineStyle, ?drawStyle:DrawStyle)
	{
		beginDraw(Color, lineStyle);

		if (dX == -1)
			dX = getPos(X);

		if (d2X == -1)
			d2X = getPos(X);

		if (dY == -1)
			dY = getPos(Y);

		if (d2Y == -1)
			d2Y = getPos(Y);

		var minusVal = Math.min(frameWidth, frameHeight);

		Main.gfx.drawRect(dX + (minusVal / 2), 0, frameWidth - (dX + (minusVal / 2)) - (d2X - (minusVal / 2)), frameHeight);
		Main.gfx.drawCircle(dX + (minusVal / 2), dY, (minusVal / 2));
		Main.gfx.drawCircle(d2X - (minusVal / 2), d2Y, (minusVal / 2));
		endDraw(drawStyle);
	}

	private function getPos(axis:FlxAxes)
	{
		var mid = getGraphicMidpoint();

		if (axis == X)
			return mid.x - x;
		if (axis == Y)
			return mid.y - y;
		if (axis == XY)
			return 0;

		mid.put();

		return 0;
	}

	private function beginDraw(FillColor:FlxColor, ?lineStyle:LineStyle)
	{
		Main.gfx.clear();
		setLineStyle(lineStyle);

		if (FillColor != FlxColor.TRANSPARENT)
			Main.gfx.beginFill(FillColor.to24Bit(), FillColor.alphaFloat);
	}

	private function endDraw(?drawStyle:DrawStyle)
	{
		if (drawStyle == null)
			drawStyle = {smoothing: false};
		else if (drawStyle.smoothing == null)
			drawStyle.smoothing = false;

		pixels.draw(Main.gfxSprite, drawStyle.matrix, drawStyle.colorTransform, drawStyle.blendMode, drawStyle.clipRect, drawStyle.smoothing);
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

			Main.gfx.lineStyle(lineStyle.thickness, color.to24Bit(), color.alphaFloat, lineStyle.pixelHinting, lineStyle.scaleMode, lineStyle.capsStyle,
				lineStyle.jointStyle, lineStyle.miterLimit);
		}
	}
}
