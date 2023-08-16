package funkin.states;

import backend.DiscordPresence;
import backend.ScriptHandler.ForeverModule;
import base.Conductor;
import base.MusicBeatState;
import base.TransitionState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.ChartLoader;
import funkin.notes.Note;
import funkin.notes.Receptor;
import funkin.notes.StrumLine;
import funkin.substates.GameOverSubstate;
import funkin.substates.PauseSubstate;
import openfl.media.Sound;
import transitions.FadeTransition;

using StringTools;

// goofy code gotta order it bruh
class QuaverGameplay extends MusicBeatState
{
	// Cameras
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	// Strum handling
	public var strums:StrumLine;

	// Countdown
	public var startedCountdown:Bool = false;
	public var startingSong:Bool = false;

	private var startTimer:FlxTimer;

	// Stage, UI and characters
	private var stageBuild:Stage;
	private var ui:UI;

	// Pause handling
	public static var paused:Bool = false;
	public static var canPause:Bool = true;

	// Cock
	private var mapID:String;

	override public function new(mapID:String)
	{
		super();

		this.mapID = mapID;
	}

	override public function create()
	{
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.stop();

		GameOverSubstate.resetVariables();
		Timings.call();
		Paths.music("tea-time");
		ChartLoader.loadBeatmap(mapID);

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		camGame.bgColor.alpha = 0;
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther, false);

		var yPos:Float = (Settings.downScroll ? FlxG.height - (FlxG.height / 8) : (FlxG.height / 8));

		strums = new StrumLine((FlxG.width / 2), yPos);
		strums.onMiss.add(noteMiss);
		strums.onBotHit.add(botHit);
		strums.cameras = [camHUD];
		add(strums);

		stageBuild = new Stage(SONG.stage);
		add(stageBuild);

		ui = new UI();
		ui.cameras = [camHUD];
		add(ui);

		Conductor.songPosition = -5000;
		FlxG.camera.zoom = 1;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		setOnModules('camGame', camGame);
		setOnModules('camHUD', camHUD);
		setOnModules('playerStrums', strums);
		setOnModules('QuaverGameplay', this);
		setOnModules('UI', ui);
		setOnModules('stepHit', stepHit);
		setOnModules('beatHit', beatHit);

		startingSong = true;

		callOnModules('onCreatePost', '');
		for (event in ChartLoader.eventQueue)
		{
			callOnModules('initFunction', event.value1, event.value2);
		}

		setupCountdown();

		super.create();

		FadeTransition.nextCamera = camOther;
	}

	override function update(elapsed:Float)
	{
		callOnModules('onUpdate', elapsed);

		super.update(elapsed);

		if (!paused)
			DiscordPresence.changePresence('Playing ${SONG.song}', ui.scoreText.text, null, true, Conductor.boundInst.length - Conductor.songPosition);

		if (startedCountdown && startingSong && !paused)
		{
			// do not toggle update time as it will resync
			Conductor.songPosition += elapsed * 1000;
		}

		if (startingSong && !paused)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if (!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}

		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));

		if (Timings.health <= 0)
		{
			callOnModules('onGameOver', null);
			updateTime = persistentDraw = persistentUpdate = false;

			Conductor.boundInst.stop();
			DiscordPresence.changePresence("Game Over");
			TransitionState.switchState(new QuaverGameplay(mapID));
		}

		while ((ChartLoader.noteQueue[0] != null) && (ChartLoader.noteQueue[0].strumTime - Conductor.songPosition) < 3500)
		{
			var nextNote:Note = ChartLoader.noteQueue[0];
			if (nextNote != null)
			{
				strums.push(nextNote);

				callOnModules('onSpawnNote', [
					ChartLoader.noteQueue.indexOf(nextNote),
					nextNote.noteData,
					nextNote.noteType,
					nextNote.isSustain
				]);
			}
			ChartLoader.noteQueue.splice(ChartLoader.noteQueue.indexOf(nextNote), 1);
		}

		holdNotes(elapsed);
		checkEventNote();

		callOnModules('onUpdatePost', elapsed);
	}

	override public function onActionPressed(action:String)
	{
		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case "confirm":
				if (canPause)
				{
					persistentUpdate = false;
					persistentDraw = true;
					openSubState(new PauseSubstate());
				}

			case "reset":
				if (startingSong)
					return;
				Timings.health = 0;

			default:
				if (!strums.botPlay && startedCountdown && !paused)
				{
					for (receptor in strums.receptors)
					{
						if (action == receptor.action)
						{
							var data:Int = receptor.noteData;
							var lastTime:Float = Conductor.songPosition;
							Conductor.songPosition = Conductor.boundInst.time;

							var possibleNotes:Array<Note> = [];
							var directionList:Array<Int> = [];
							var dumbNotes:Array<Note> = [];

							strums.notesGroup.forEachAlive(function(daNote:Note)
							{
								if ((daNote.noteData == data) && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustain)
								{
									if (directionList.contains(data))
									{
										for (coolNote in possibleNotes)
										{
											if (coolNote.noteData == daNote.noteData
												&& Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
											{
												dumbNotes.push(daNote);
												break;
											}
											else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
											{
												possibleNotes.remove(coolNote);
												possibleNotes.push(daNote);
												break;
											}
										}
									}
									else
									{
										possibleNotes.push(daNote);
										directionList.push(data);
									}
								}
							});

							for (note in dumbNotes)
							{
								strums.destroyNote(note);
							}

							if (possibleNotes.length > 0)
							{
								for (coolNote in possibleNotes)
								{
									noteHit(coolNote);
								}
							}

							Conductor.songPosition = lastTime;

							if (receptor.animation.curAnim.name != "confirm")
								receptor.playAnim('pressed');
						}
					}
				}
		}
		callOnModules('onKeyPress', action);
	}

	override public function onActionReleased(action:String)
	{
		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case "confirm" | "back" | "reset":
				return;

			default:
				if (!strums.botPlay && startedCountdown && !paused)
				{
					for (receptor in strums.receptors)
					{
						if (action == receptor.action)
						{
							receptor.playAnim('static');
						}
					}
				}
		}
		callOnModules('onKeyRelease', action);
	}

	private function holdNotes(elapsed:Float)
	{
		if (strums == null || paused)
			return;

		var holdArray:Array<Bool> = [
			controls.note_left.state == PRESSED,
			controls.note_down.state == PRESSED,
			controls.note_up.state == PRESSED,
			controls.note_right.state == PRESSED
		];

		if (!strums.botPlay)
		{
			strums.allNotes.forEachAlive(function(coolNote:Note)
			{
				if (holdArray[coolNote.noteData])
				{
					if ((coolNote.parent != null && coolNote.parent.wasGoodHit)
						&& coolNote.canBeHit
						&& !coolNote.tooLate
						&& !coolNote.wasGoodHit
						&& coolNote.isSustain
						&& coolNote.holdActive)
					{
						noteHit(coolNote);
					}
				}
			});
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (!paused)
		{
			if (Conductor.boundInst != null)
				Conductor.boundInst.pause();

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;

			DiscordPresence.changePresence('Playing ${SONG.song}', "Paused");
			paused = true;
			callOnModules('onPause', null);
			canPause = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (!startingSong)
				Conductor.resyncTime();

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;

			DiscordPresence.changePresence('Playing ${SONG.song}');
			paused = false;
			callOnModules('onResume', null);
			canPause = true;
		}

		super.closeSubState();
	}

	private function setupCountdown()
	{
		for (receptor in strums.receptors)
		{
			receptor.y -= 32;
			receptor.alpha = 0;
		}
		ui.alpha = 0;

		startCountdown();
	}

	private function startCountdown()
	{
		if (startedCountdown)
		{
			callOnModules('onStartCountdown', null);
			return;
		}

		callOnModules('onStartCountdown', null);

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var i = 0;
		for (receptor in strums.receptors)
		{
			FlxTween.tween(receptor, {y: receptor.initialY, alpha: receptor.setAlpha}, (Conductor.crochet * 4) / 1000,
				{ease: FlxEase.circOut, startDelay: (Conductor.crochet / 1000) + ((Conductor.stepCrochet / 1000) * i)});
			i++;
		}
		FlxTween.tween(ui, {alpha: 1}, (Conductor.crochet * 2) / 1000, {startDelay: (Conductor.crochet / 1000)});

		setOnModules('startedCountdown', true);
		callOnModules('onCountdownStarted', null);

		var introArray:Array<FlxGraphic> = [];
		var soundsArray:Array<Sound> = [];

		if (!stageBuild.skip_defaultCountdown)
		{
			var introName:Array<String> = ['ready', 'set', 'go'];
			for (intro in introName)
				introArray.push(Paths.image('ui/$intro'));

			var soundNames:Array<String> = ['intro3', 'intro2', 'intro1', 'introGo'];
			for (sound in soundNames)
				soundsArray.push(Paths.sound(sound));
		}

		var countdown:Int = -1;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, (tmr:FlxTimer) ->
		{
			if (!stageBuild.skip_defaultCountdown && countdown >= 0 && countdown < introArray.length)
			{
				var introSprite:FlxSprite = new FlxSprite().loadGraphic(introArray[countdown]);
				introSprite.scrollFactor.set();
				introSprite.updateHitbox();
				introSprite.screenCenter();
				introSprite.cameras = [camHUD];
				add(introSprite);

				FlxTween.tween(introSprite, {y: introSprite.y + 100, alpha: 0}, Conductor.crochet / 1000, {
					ease: FlxEase.cubeInOut,
					onComplete: (_) ->
					{
						introSprite.destroy();
					}
				});
			}

			callOnModules('onCountdownTick', countdown);

			countdown++;
			if (!stageBuild.skip_defaultCountdown)
				FlxG.sound.play(soundsArray[countdown], 0.6);
		}, 5);
	}

	private function startSong()
	{
		startingSong = false;

		Conductor.boundInst.play();
		Conductor.boundInst.onComplete = endSong.bind();

		updateTime = true;

		setOnModules('songLength', Conductor.boundInst.length);
		callOnModules('onSongStart', null);
	}

	override public function stepHit()
	{
		setOnModules('curStep', curStep);
		callOnModules('onStepHit', []);
	}

	override public function beatHit()
	{
		super.beatHit();

		if (curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		setOnModules('curBeat', curBeat);
		callOnModules('onBeatHit', []);
	}

	private function noteHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			var receptor:Receptor = getReceptor(strums, note.noteData);
			note.wasGoodHit = true;
			receptor.playAnim('confirm', true);

			if (!note.isSustain)
			{
				var rating:String = Timings.judge(Math.abs(note.strumTime - Conductor.songPosition));
				ui.displayJudgement(rating, (note.strumTime < Conductor.songPosition));
				strums.generateSplash(receptor);
			}

			callOnModules('goodNoteHit', [
				ChartLoader.noteQueue.indexOf(note),
				note.noteData,
				note.noteType,
				note.isSustain
			]);

			if (!note.isSustain)
				strums.destroyNote(note);
		}
	}

	private function noteMiss(note:Note)
	{
		Timings.judge(Timings.judgements[Timings.judgements.length - 1].timing);
		ui.displayJudgement('miss', true);

		callOnModules('noteMiss', [
			ChartLoader.noteQueue.indexOf(note),
			note.noteData,
			note.noteType,
			note.isSustain
		]);
	}

	private function botHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			var receptor:Receptor = getReceptor(strums, note.noteData);
			note.wasGoodHit = true;

			var time:Float = 0.15;
			if (note.isSustain && !note.isSustainEnd)
				time += 0.15;

			receptor.playAnim('confirm', true);
			receptor.holdTimer = time;

			if (!note.isSustain)
				strums.generateSplash(receptor);

			callOnModules("goodNoteHit", [
				ChartLoader.noteQueue.indexOf(note),
				note.noteData,
				note.noteType,
				note.isSustain
			]);

			if (!note.isSustain)
				strums.destroyNote(note);
		}
	}

	private function endSong():Void
	{
		updateTime = false;
		Conductor.boundInst.stop();
		callOnModules('onEndSong', null);
		TransitionState.switchState(new SongSelection());
	}

	private function checkEventNote()
	{
		while (ChartLoader.eventQueue.length > 0)
		{
			var leStrumTime:Float = ChartLoader.eventQueue[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
				break;

			var module:ForeverModule = Events.loadedModules.get(ChartLoader.eventQueue[0].event);

			var value1:String = "";
			if (ChartLoader.eventQueue[0].value1 != null)
				value1 = ChartLoader.eventQueue[0].value1;

			var value2:String = "";
			if (ChartLoader.eventQueue[0].value2 != null)
				value2 = ChartLoader.eventQueue[0].value2;

			try
			{
				if (module.exists("eventFunction"))
					module.get("eventFunction")(value1, value2);
			}
			catch (ex)
			{
				trace('Failed to execute event ($ex)');
			}
			ChartLoader.eventQueue.shift();
		}
	}

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];
}
