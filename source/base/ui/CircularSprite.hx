package base.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxBitmapText;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil.DrawStyle;
import flixel.util.FlxSpriteUtil.LineStyle;
import funkin.CoolUtil;

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
		drawStuff((x), -1, (x + width), -1, {thickness: 0, color: FlxColor.TRANSPARENT}, null);
		antialiasing = SaveData.antialiasing;
	}

	private function drawStuff(dX:Float = -1, dY:Float = -1, d2X:Float = -1, d2Y:Float = -1, ?lineStyle:LineStyle, ?drawStyle:DrawStyle)
	{
		if (dX == -1)
			dX = getPos(X);

		if (d2X == -1)
			d2X = getPos(X);

		if (dY == -1)
			dY = getPos(Y);

		if (d2Y == -1)
			d2Y = getPos(Y);

		var minusVal = Math.min(frameWidth, frameHeight);

		beginDraw(Color, lineStyle);
		Main.gfx.drawCircle(dX + (minusVal / 2), dY, (minusVal / 2));
		Main.gfx.drawCircle(d2X - (minusVal / 2), d2Y, (minusVal / 2));
		endDraw(drawStyle);

		beginDraw(Color, lineStyle);
		Main.gfx.drawRect(dX + (minusVal / 2), 0, frameWidth - (2 * (minusVal / 2)), frameHeight);
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

class CircularSpriteText extends FlxSpriteGroup
{
	public var circularSprite(default, null):CircularSprite;
	public var bitmapText(default, null):FlxBitmapText;
	public var fontSize:Float;

	// For menu stuff
	public var selected:Bool = false;

	public var menuItem:Bool = false;
	public var targetY:Float = 0;

	override public function new(X:Float, Y:Float, Width:Float, Height:Float, Color:FlxColor, Text:String)
	{
		super(X, Y);

		circularSprite = new CircularSprite(0, 0, Width, Height, Color);
		circularSprite.alpha = 0.45;
		add(circularSprite);

		bitmapText = new FlxBitmapText(Fonts.VCR());
		bitmapText.text = Text;
		bitmapText.fieldWidth = Std.int(width);
		bitmapText.antialiasing = SaveData.antialiasing;
		setFontSize(X, Y, 0.4);
		add(bitmapText);
	}

	function setFontSize(oX:Float, oY:Float, value:Float):Float
	{
		if (fontSize == value)
			return value;

		bitmapText.setGraphicSize(Std.int(bitmapText.width * value));
		bitmapText.centerOffsets();
		bitmapText.updateHitbox();
		bitmapText.setPosition(10, 10);

		return fontSize = value;
	}

	override public function update(elapsed:Float)
	{
		var slowLerp:Float = funkin.CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		var lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 5.125), 0, 1);

		circularSprite.alpha = FlxMath.lerp((selected ? 0.9 : 0.45), circularSprite.alpha, lerpVal);
		circularSprite.scale.x = FlxMath.lerp((selected ? 1.1 : 1), circularSprite.scale.x, lerpVal);
		bitmapText.alpha = FlxMath.lerp(circularSprite.alpha, bitmapText.alpha, lerpVal);

		if (menuItem)
		{
			var scaledY:Float = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
			y = FlxMath.lerp(y, (scaledY) + (FlxG.height * 0.48), slowLerp);
		}

		super.update(elapsed);
	}
}
