package states;

import base.MusicBeatState;
import base.system.Controls;
import base.ui.CircularSprite;
import base.ui.RoundedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

class RewriteMenu extends MusicBeatState
{
	var options:Array<String> = ["Online", "Settings", "Shaders", "Character selection"];
	var groupItems:FlxTypedGroup<RoundedSpriteText>;
	var curOption(default, set):Int = 0;

	private function set_curOption(value:Int):Int
	{
		curOption += value;

		if (curOption < 0)
			curOption = options.length - 1;
		if (curOption >= options.length)
			curOption = 0;

		return curOption;
	}

	override public function create()
	{
		Controls.setActions(UI);

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuSDefault2"));
		bg.screenCenter();
		bg.antialiasing = SaveData.antialiasing;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		add(bg);

		groupItems = new FlxTypedGroup<RoundedSpriteText>();
		add(groupItems);

		for (option in options)
		{
			var item:RoundedSpriteText = new RoundedSpriteText(0, 0, 325, 50, FlxColor.RED, option);
			item.roundedSprite.cornerSize = 25;
			groupItems.add(item);
		}

		var circ = new CircularSprite(0, 0, 300, 80, FlxColor.LIME);
		circ.screenCenter();
		add(circ);

		super.create();
	}
}

enum SelectionState
{
	SELECTING;
	SUB_SELECTION;
	LISTING;
}
