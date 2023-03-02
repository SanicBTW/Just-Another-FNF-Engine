package substates;

import base.ScriptableState;
import base.system.Conductor;
import base.system.Controls;
import base.system.SoundManager;
import base.ui.Alphabet;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.ChartLoader;
import states.PlayTest;

class PauseState extends ScriptableSubState
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [
		'Resume',
		'Reset song',
		PlayTest.instance.playerStrums.botPlay ? "Disable botplay" : "Enable botplay",
		'Exit'
	];
	var curSelected:Int = 0;
	var bgMusic:AudioStream;

	public function new()
	{
		super();
		Controls.setActions(UI);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		bgMusic = SoundManager.setSound("pause");
		bgMusic.audioSource = Paths.music("tea-time");
		bgMusic.play(0, FlxG.random.int(0, Std.int(bgMusic.audioLength / 2)));
		bgMusic.loopAudio = true;

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var pauseItem:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i].toString(), true, false);
			pauseItem.isMenuItem = true;
			pauseItem.targetY = i;
			pauseItem.ID = i;
			grpMenuShit.add(pauseItem);
		}

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override public function update(elapsed:Float)
	{
		if (bgMusic.audioVolume < 0.5)
			bgMusic.audioVolume += 0.01 * elapsed;

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
							Controls.setActions(NOTES);
							bgMusic.stop();
							close();
						case 'Enable botplay' | "Disable botplay":
							PlayTest.instance.playerStrums.botPlay = !PlayTest.instance.playerStrums.botPlay;
							grpMenuShit.members[2].changeText(PlayTest.instance.playerStrums.botPlay ? "Disable botplay" : "Enable botplay");
						case 'Reset song':
							bgMusic.stop();
							ScriptableState.switchState(new PlayTest());
						case 'Exit':
							bgMusic.stop();
							Conductor.boundSong.stop();
							Conductor.boundVocals.stop();
							ChartLoader.netInst = null;
							ChartLoader.netVoices = null;
							ScriptableState.switchState(new states.MainState());
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
