package states.config;

class AlphabetSelector extends flixel.group.FlxSpriteGroup
{
	private var bg:flixel.FlxSprite;
	private var alphText:base.Alphabet;

	public function new(text:String, targetY:Float = 0, yMult = 0)
	{
		super();

		alphText = new base.Alphabet(0, 0, text, true, false);
		alphText.isMenuItem = true;
		alphText.targetY = targetY;
		alphText.yMult = yMult;
		alphText.alpha = 0.5;

		bg = new flixel.FlxSprite().makeGraphic(Std.int(alphText.width + 20), Std.int(alphText.height + 20), flixel.util.FlxColor.BLACK);
		bg.alpha = 0.5;

		add(bg);
		add(alphText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		bg.x = alphText.x - 10;
		bg.y = alphText.y - 10;

		if (flixel.FlxG.mouse.overlaps(this))
		{
			alphText.alpha = 1;
			bg.alpha = 0.6;
		}
		else
		{
			alphText.alpha = 0.5;
			bg.alpha = 0.5;
		}
	}
}
