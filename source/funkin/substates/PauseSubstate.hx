package funkin.substates;

import backend.Controls;
import base.ScriptableState.ScriptableSubState;
import base.ScriptableState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.states.PlayState;
import funkin.states.SongSelection;
import funkin.text.Alphabet;

class PauseSubstate extends ScriptableSubState
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var menuItems:Array<String> = ['Resume', 'Reset song', 'Exit'];
	var curSelected:Int = 0;
	var pauseMusic:FlxSound;

	public function new()
	{
		super();
		Controls.targetActions = UI;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		pauseMusic = new FlxSound().loadEmbedded(Paths.music("tea-time"), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var pauseItem:Alphabet = new Alphabet(90, 320, menuItems[i].toString(), true);
			pauseItem.isMenuItem = true;
			pauseItem.targetY = i - curSelected;
			grpMenuShit.add(pauseItem);
		}

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override public function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);
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
							Controls.targetActions = NOTES;
							close();
						case 'Reset song':
							ScriptableState.switchState(new PlayState());
						case 'Exit':
							ScriptableState.switchState(new SongSelection());
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
				menuItem.alpha = 1;
		});
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}
}
