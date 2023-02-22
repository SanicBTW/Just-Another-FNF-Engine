package states;

import base.ScriptableState;
import base.SoundManager;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;

class Fuckstat extends ScriptableState
{
	var grou:FlxSpriteGroup;
	var shitshow:PlaybackGraph;

	override public function create()
	{
		grou = new FlxSpriteGroup();
		grou.screenCenter();
		add(grou);

		var fuck = SoundManager.setSound("test");
		fuck.audioSource = Paths.inst('recursed');
		fuck.loopAudio = true;
		fuck.play();

		shitshow = new PlaybackGraph();
		for (i in shitshow.bars)
		{
			grou.add(i);
		}
	}

	override public function update(elapsed:Float)
	{
		shitshow.Update(elapsed);
	}
}
