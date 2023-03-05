package base.ui;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil.DrawStyle;
import flixel.util.FlxSpriteUtil.LineStyle;

using flixel.util.FlxColorTransformUtil;

class RoundedSprite extends FlxSprite
{
	public var cornerSize(default, set):Float;

	private var Color:FlxColor;

	private var _regen:Bool = true;

	private function set_cornerSize(Value:Float):Float
	{
		if (cornerSize == Value)
			return Value;

		cornerSize = Value;

		drawRoundRect({thickness: 0, color: FlxColor.TRANSPARENT}, {smoothing: true});
		_regen = true;
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
	}

	override public function drawFrame(Force:Bool = false)
	{
		_regen = _regen || Force;
		super.drawFrame(_regen);
	}

	override public function draw()
	{
		// USE WITH THE UPCOMING POP UPS
		// camera.startQuadBatch(Round.graphic, true, (colorTransform != null && colorTransform.hasRGBAOffsets()), blend, antialiasing, shader);

		_regen = false;
		super.draw();
	}

	private function drawRoundRect(?lineStyle:LineStyle, ?drawStyle:DrawStyle)
	{
		beginDraw(Color, lineStyle);
		Main.gfx.drawRoundRectComplex(x, y, width, height, cornerSize, cornerSize, cornerSize, cornerSize);
		endDraw(drawStyle);
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

// I didn't really think of any other way
class RoundedSpriteText extends FlxSpriteGroup
{
	public var roundedSprite(default, null):RoundedSprite;
	public var bitmapText(default, null):FlxBitmapText;
	public var fontSize(default, set):Float;

	override public function new(X:Float, Y:Float, Width:Float, Height:Float, Color:FlxColor, Text:String)
	{
		super();

		roundedSprite = new RoundedSprite(X, Y, Width, Height, Color);
		roundedSprite.antialiasing = SaveData.antialiasing;
		add(roundedSprite);

		bitmapText = new FlxBitmapText(Fonts.VCR());
		bitmapText.text = Text;
		bitmapText.fieldWidth = Std.int(width);
		bitmapText.antialiasing = SaveData.antialiasing;
		fontSize = 0.4;
		add(bitmapText);
	}

	function set_fontSize(value:Float):Float
	{
		if (fontSize == value)
			return value;

		bitmapText.setGraphicSize(Std.int(bitmapText.width * value));
		bitmapText.centerOffsets();
		bitmapText.updateHitbox();
		bitmapText.setPosition(roundedSprite.x + 10, roundedSprite.y + 10);

		return fontSize = value;
	}
}
