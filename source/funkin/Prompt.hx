package funkin;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

// change font to funkin
class Prompt extends FlxSpriteGroup
{
	public var title:FlxText;
	public var description:FlxText;
	public var footer:FlxText;

	public function new(title:String = "Placeholder", description:String = "Placeholder", footer:String = "Placeholder")
	{
		super();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/promptbg'));
		bg.antialiasing = SaveData.antialiasing;
		add(bg);

		this.title = new FlxText(bg.x + 105, bg.y + 30, bg.width - 132, title, 25);
		this.title.setFormat("_sans", 25, FlxColor.BLACK, LEFT);
		this.title.antialiasing = SaveData.antialiasing;
		add(this.title);

		this.description = new FlxText(bg.x + 12, this.title.y + 50, bg.width - 32, description, 20);
		this.description.setFormat("_sans", 20, FlxColor.BLACK, LEFT);
		this.description.antialiasing = SaveData.antialiasing;
		add(this.description);

		this.footer = new FlxText(bg.x + 12, this.description.y + 210, bg.width - 32, footer, 20);
		this.footer.setFormat("_sans", 20, FlxColor.BLACK, LEFT);
		this.footer.antialiasing = SaveData.antialiasing;
		add(this.footer);
	}
}
