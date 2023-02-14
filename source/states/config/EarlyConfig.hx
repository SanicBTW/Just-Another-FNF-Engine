package states.config;

import base.Alphabet;
import base.Controls;
import base.SaveData;
import base.ScriptableState;
import base.ui.TextComponent;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class EarlyConfig extends ScriptableState
{
	var grpItems:FlxTypedGroup<Alphabet>;
	var menuArray:Array<String> = [];
	var curSelected(default, set):Int = 0;
	var stateBG:FlxSprite;
	var stateText:FlxText;

	private function set_curSelected(value:Int):Int
	{
		curSelected += value;

		if (curSelected < 0)
			curSelected = menuArray.length - 1;
		if (curSelected >= menuArray.length)
			curSelected = 0;

		var tf:Int = 0;

		for (item in grpItems.members)
		{
			item.targetY = tf - curSelected;
			tf++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}

		checkState();

		return curSelected;
	}

	override public function create()
	{
		Controls.setActions(UI);

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuSDefault2"));
		bg.screenCenter();
		bg.antialiasing = SaveData.antialiasing;
		bg.alpha = 0.5;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		add(bg);

		stateText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		stateText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		stateBG = new FlxSprite(stateText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		stateBG.alpha = 0.6;
		add(stateBG);
		add(stateText);

		grpItems = new FlxTypedGroup<Alphabet>();
		add(grpItems);

		menuArray = SaveData.getSettings();
		regenMenu();

		super.create();
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		switch (action)
		{
			case "back":
				SaveData.saveSettings();
				ScriptableState.switchState(new MainState());
			case "ui_up":
				curSelected = -1;
			case "ui_down":
				curSelected = 1;
			case "confirm":
				{
					Reflect.setField(SaveData, menuArray[curSelected], !Reflect.field(SaveData, menuArray[curSelected]));
				}
		}
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);

		switch (action)
		{
			case "confirm":
				checkState();
		}
	}

	private function checkState()
	{
		stateText.text = '${Reflect.field(SaveData, menuArray[curSelected])}';
		setPosition();
	}

	private function regenMenu()
	{
		for (i in 0...grpItems.members.length)
		{
			grpItems.remove(grpItems.members[0], true);
		}
		for (i in 0...menuArray.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuArray[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpItems.add(songText);
			if (songText.width > 980)
			{
				var textScale:Float = 980 / songText.width;
				songText.scale.x = textScale;
				for (letter in songText.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
			}
		}
		curSelected = 0;
	}

	private function setPosition()
	{
		stateText.x = FlxG.width - stateText.width - 6;

		stateBG.scale.x = FlxG.width - stateText.x + 6;
		stateBG.x = FlxG.width - (stateBG.scale.x / 2);
	}
}
