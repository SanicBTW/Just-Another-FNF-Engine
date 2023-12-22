package quaver.substates;

import backend.input.Controls.ActionType;
import base.TransitionState;
import flixel.*;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.tweens.*;
import flixel.util.FlxColor;
import funkin.text.Alphabet;
import quaver.states.*;

// Gotta just use one PauseSubState instead of makin a copy of it ngl
class PauseSubstate extends FlxSubState
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var menuItems:Array<String> = ['Resume', 'Reset song', 'Exit'];
	var curSelected:Int = 0;
	var pauseMusic:FlxSound;

	public function new()
	{
		super();

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
			var pauseItem:Alphabet = new Alphabet(bg.getGraphicMidpoint().x, FlxG.height - 400, menuItems[i].toString(), true);
			pauseItem.alignment = CENTERED;
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

	override public function onActionPressed(action:ActionType)
	{
		super.onActionPressed(action);

		switch (action)
		{
			default:
				return;

			case UI_UP:
				changeSelection(-1);
			case UI_DOWN:
				changeSelection(1);
			case CONFIRM:
				{
					switch (menuItems[curSelected])
					{
						case "Resume":
							close();
						case 'Reset song':
							TransitionState.switchState(new QuaverGameplay());
						case 'Exit':
							TransitionState.switchState(new QuaverSelection());
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
