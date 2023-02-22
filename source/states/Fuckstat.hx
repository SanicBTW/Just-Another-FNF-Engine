package states;

import base.ScriptableState;
import base.SoundManager;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;

class Fuckstat extends ScriptableState
{
	var shitshow:PlaybackGraph;

	override public function create()
	{
		var fuck = SoundManager.setSound("test", null);
		fuck.audioSource = Paths.music("freakyMenu");
		fuck.loopAudio = true;
		fuck.play();

		shitshow = new PlaybackGraph();
		add(shitshow);
	}
}
