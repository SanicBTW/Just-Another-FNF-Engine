package funkin.substates;

import backend.Conductor;
import backend.input.Controls;
import base.MusicBeatState;
import base.TransitionState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.Character;

// PE
class GameOverSubstate extends MusicBeatSubState
{
	private var playerDead:Character;
	private var isEnding:Bool = false;
	private var bop:Bool = false;

	// Camera stuff
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;
	private var updateCamera:Bool = false;

	public static var snapCamera:Bool = false;

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
		snapCamera = false;
	}

	override function create()
	{
		callOnModules('onGameOverStart', null);

		super.create();
	}

	public function new(X:Float, Y:Float)
	{
		super();

		removeListeners();

		callOnModules('inGameOver', null);

		Conductor.time = 0;
		updateTime = false;

		playerDead = new Character(X, Y, true, characterName);
		add(playerDead);

		setOnModules('boyfriend_dead', playerDead);

		// why not
		var camPos:FlxPoint = new FlxPoint(playerDead.getGraphicMidpoint().x, playerDead.getGraphicMidpoint().y);

		FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(100);
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		playerDead.playAnim('firstDeath');

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));

		if (snapCamera)
		{
			camFollow.setPosition(playerDead.getGraphicMidpoint().x, playerDead.getGraphicMidpoint().y);
			camFollowPos.setPosition(playerDead.getGraphicMidpoint().x, playerDead.getGraphicMidpoint().y);
		}

		add(camFollow);
		add(camFollowPos);
	}

	override public function update(elapsed:Float)
	{
		callOnModules('onUpdate', elapsed);

		super.update(elapsed);

		if (updateCamera)
		{
			var lerpVal:Float = FlxMath.bound(elapsed * 0.6, 0, 1);
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
				playerDead.startedDeath = true;
				bop = true;
			}
		}

		callOnModules('onUpdatePost', elapsed);
	}

	override public function onActionPressed(action:ActionType)
	{
		super.onActionPressed(action);

		switch (action)
		{
			default:
				return;

			case CONFIRM:
				callOnModules('onGameOverConfirm', true);
				finish(() ->
				{
					TransitionState.switchState(new funkin.states.PlayState());
				});
			case BACK:
				callOnModules('onGameOverConfirm', false);
				finish(() ->
				{
					TransitionState.switchState(new funkin.states.SongSelection());
				});
		}
	}

	override public function beatHit(beat:Int)
	{
		super.beatHit(beat);

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
		@:privateAccess
		{
			Controls.onActionPressed.remove(currentState.onActionPressed);
			Controls.onActionReleased.remove(currentState.onActionReleased);
			Conductor.onStepHit.remove(currentState.stepHit);
			Conductor.onBeatHit.remove(currentState.beatHit);
			Conductor.boundInst = null;
			Conductor.boundVocals = null;
		}
	}
}
