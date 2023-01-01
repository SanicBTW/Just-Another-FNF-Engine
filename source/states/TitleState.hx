package states;

import base.Conductor;
import base.MusicBeatState;
import base.SaveData;
import base.ScriptableState;
import base.SoundManager;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;
	public static var closedState:Bool = false;

	var gfDance:FlxSprite;
	var danceLeft:Bool = false;

	var logoBl:FlxSprite;

	override public function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		super.create();

		#if !cpp
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			beginIntro();
		});
		#else
		beginIntro();
		#end
	}

	function beginIntro()
	{
		if (!initialized)
		{
			if (SoundManager.backgroundMusic == null)
			{
				SoundManager.setBGMusic("freakyMenu", 0);
				SoundManager.fadeInBGMusic(4, 0, 0.7);
			}
		}

		// to make the state update the conductor contents
		Conductor.bindCustom(this, SoundManager.backgroundMusic, 102);

		logoBl = new FlxSprite(-150, -100);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = SaveData.antialiasing;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = SaveData.antialiasing;
		add(gfDance);
		add(logoBl);
	}

	override function beatHit()
	{
		super.beatHit();

		if (logoBl != null)
			logoBl.animation.play('bump');

		if (gfDance != null)
		{
			danceLeft = !danceLeft;

			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}
	}

	override function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (action == "confirm")
		{
			SoundManager.backgroundMusic.stop();
			ScriptableState.switchState(new PlayTest());
		}
	}
}
