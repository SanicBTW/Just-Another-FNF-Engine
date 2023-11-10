package start;

import backend.Conductor;
import backend.io.CacheFile;
import base.MusicBeatState;
import base.sprites.StateBG;
import flixel.FlxG;

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

		super.create();

		if (!CacheFile.data.gavePerms)
			openSubState(new PermissionsSubstate());
	}
}
