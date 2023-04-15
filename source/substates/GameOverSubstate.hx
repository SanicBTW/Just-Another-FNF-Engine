package substates;

import base.MusicBeatState.MusicBeatSubState;
import base.MusicBeatState;
import base.ScriptableState;
import base.system.Conductor;
import base.system.Controls;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.Character;
import funkin.CoolUtil;
import states.PlayTest;

// PE - Music not working
class GameOverSubstate extends MusicBeatSubState
{
	private var playerDead:Character;
	private var isEnding:Bool = false;
	private var bop:Bool = false;

	// Camera stuff
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;
	private var updateCamera:Bool = false;

	// Totally psych shit lmao
	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static function resetVariables()
	{
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	public function new(X:Float, Y:Float)
	{
		super();

		removeListeners();

		Conductor.songPosition = 0;
		updateTime = false;

		playerDead = new Character(X, Y, true, characterName);
		add(playerDead);

		// why not
		var camPos:FlxPoint = new FlxPoint(playerDead.x + (playerDead.width / 2), playerDead.y + (playerDead.height / 2));

		FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(100);
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		playerDead.playAnim('firstDeath');

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));

		add(camFollow);
		add(camFollowPos);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (updateCamera)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (playerDead.animation.curAnim.name == 'firstDeath')
		{
			if (playerDead.animation.curAnim.curFrame >= 12)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				updateTime = true;
			}

			if (playerDead.animation.curAnim.finished)
			{
				FlxG.sound.playMusic(Paths.music(loopSoundName), 1);
				bop = true;
			}
		}
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		switch (action)
		{
			case "confirm":
				finish(() ->
				{
					ScriptableState.switchState(new PlayTest(PlayTest.instance.loadSong));
				});
			case "back":
				finish(() ->
				{
					ScriptableState.switchState(new states.RewriteMenu());
				});
		}
	}

	override public function beatHit()
	{
		super.beatHit();

		if (bop && !isEnding)
			playerDead.playAnim('deathLoop', true);
	}

	private function finish(end:Void->Void)
	{
		if (!isEnding)
		{
			isEnding = true;
			playerDead.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, end);
			});
		}
	}

	private function removeListeners()
	{
		var currentState:MusicBeatState = cast(FlxG.state, MusicBeatState);
		Controls.onActionPressed.remove(currentState.onActionPressed);
		Controls.onActionReleased.remove(currentState.onActionReleased);
		Conductor.onStepHit.remove(currentState.stepHit);
		Conductor.onBeatHit.remove(currentState.beatHit);
		Conductor.boundSong = null;
		Conductor.boundVocals = null;
	}
}
