package start;

import backend.Conductor;
import base.MusicBeatState;
import base.sprites.StateBG;
import flixel.FlxG;
import funkin.Prompt.Arrow_Buttons;
import funkin.Prompt.PromptButton;

class MainState extends MusicBeatState
{
	var bg:StateBG;

	override function create()
	{
		FlxG.sound.playMusic(Paths.music("freakyMenu"));
		Conductor.changeBPM(102, false);

		bg = new StateBG('menuBG');
		bg.screenCenter();
		add(bg);

		var cockButton:PromptButton = new PromptButton(0, 0, () ->
		{
			trace("cock");
		}, ARROWS, Arrow_Buttons.UP);
		cockButton.screenCenter();
		add(cockButton);

		super.create();
	}
}
