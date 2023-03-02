package states.config;

class KeybindSelector extends flixel.group.FlxSpriteGroup
{
	private var bg:flixel.FlxSprite;

	public var bitText:flixel.text.FlxBitmapText;
	public var subBitText:flixel.text.FlxBitmapText;

	public var action:String;
	public var baseKey:String;

	public var targetY:Float = 0;
	public var yMult:Float = 120;
	public var yAdd:Float = 0;

	public var forceX:Float = Math.NEGATIVE_INFINITY;

	public function new(x:Float, y:Float, text:String, ?bgWidth:Int, ?bgHeight:Int, ?subText:String)
	{
		super(x, y);

		bitText = new flixel.text.FlxBitmapText(base.ui.Fonts.VCR());
		bitText.text = text;
		bitText.alignment = CENTER;
		bitText.antialiasing = SaveData.antialiasing;

		bg = new flixel.FlxSprite().makeGraphic(bgWidth == null ? Std.int(bitText.width) : bgWidth, bgHeight == null ? Std.int(bitText.height) : bgHeight,
			flixel.util.FlxColor.BLACK);
		bg.alpha = 0.5;
		bg.antialiasing = SaveData.antialiasing;

		if (subText != null)
		{
			subBitText = new flixel.text.FlxBitmapText(base.ui.Fonts.VCR());
			subBitText.text = subText;
			subBitText.alignment = RIGHT;
			subBitText.autoSize = false;
			subBitText.fieldWidth = Std.int(bg.width);
			subBitText.antialiasing = SaveData.antialiasing;
			subBitText.x = ((bg.y + bg.width) - subBitText.width);
		}

		add(bg);
		add(bitText);

		if (subBitText != null)
			add(subBitText);
	}

	override public function update(elapsed:Float)
	{
		var slowLerp:Float = funkin.CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		var lerpVal:Float = funkin.CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1);

		// X and Y Positions
		var scaledY:Float = flixel.math.FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
		y = flixel.math.FlxMath.lerp(y, (scaledY * yMult) + (flixel.FlxG.height * 0.48) + yAdd, slowLerp);
		if (forceX != Math.NEGATIVE_INFINITY)
			x = flixel.math.FlxMath.lerp(x, forceX, slowLerp);
		else
			x = flixel.math.FlxMath.lerp(x, (targetY * 20) + 90, slowLerp);

		// Text alpha
		bitText.alpha = flixel.math.FlxMath.lerp(alpha, bitText.alpha, lerpVal);
		if (subBitText != null)
			subBitText.alpha = flixel.math.FlxMath.lerp(alpha, subBitText.alpha, lerpVal);

		// BG Alpha
		bg.alpha = flixel.math.FlxMath.lerp(alpha * 0.5, bg.alpha, lerpVal);

		super.update(elapsed);
	}
}
