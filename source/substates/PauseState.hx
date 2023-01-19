package substates;

import base.Alphabet;
import base.Controls;
import base.ScriptableState.ScriptableSubState;
import base.ScriptableState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import states.PlayTest;

class PauseState extends ScriptableSubState
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['Resume', 'Reset song', 'Exit'];
	var curSelected:Int = 0;

	public function new()
	{
		super();
		Controls.setActions(UI);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var pauseItem:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i].toString(), true, false);
			pauseItem.isMenuItem = true;
			pauseItem.targetY = i;
			grpMenuShit.add(pauseItem);
		}

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		switch (action)
		{
			case "ui_up":
				changeSelection(-1);
			case "ui_down":
				changeSelection(1);
			case "confirm":
				{
					switch (menuItems[curSelected])
					{
						case "Resume":
							Controls.setActions(NOTES);
							close();
						case 'Reset song':
							ScriptableState.switchState(new PlayTest());
						case 'Exit':
							ScriptableState.switchState(new states.OnlineSongs());
					}
				}
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var what:Int = 0;

		grpMenuShit.forEach(function(menuItem:Alphabet)
		{
			menuItem.targetY = what - curSelected;
			what++;

			menuItem.alpha = 0.5;

			if (menuItem.targetY == 0)
			{
				menuItem.alpha = 1;
			}
		});
	}
}
