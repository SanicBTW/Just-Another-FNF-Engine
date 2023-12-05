package quaver.states;

import backend.Cache;
import backend.Conductor;
import backend.DiscordPresence;
import backend.input.Controls.ActionType;
import backend.scripting.ForeverModule;
import base.MusicBeatState;
import base.TransitionState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.*;
import funkin.Events.EventNote;
import funkin.notes.Note;
import funkin.notes.Receptor;
import funkin.notes.StrumLine;
import funkin.substates.GameOverSubstate;
import funkin.substates.PauseSubstate;
import openfl.media.Sound;
import quaver.Qua;
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
	private var strumLines:FlxTypedGroup<StrumLine>;

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
	private var qua:Qua;

	override public function create()
	{
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.stop();

		GameOverSubstate.resetVariables();
		Timings.call();
		Paths.music("tea-time");
		qua = ChartLoader.loadBeatmap(QuaverSelection.mapID);

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

		strumLines = new FlxTypedGroup<StrumLine>();
		strumLines.cameras = [camHUD];

		var yPos:Float = (Settings.downScroll ? FlxG.height - (FlxG.height / 8) : (FlxG.height / 6));

		strums = new StrumLine((FlxG.width / 2), yPos);
		strums.onMiss.add(noteMiss);
		strums.onBotHit.add(botHit);
		strumLines.add(strums);
		add(strumLines);

		stageBuild = new Stage(SONG.stage);
		add(stageBuild);

		ui = new UI();
		ui.cameras = [camHUD];
		add(ui);

		Conductor.time = -5000;
		FlxG.camera.zoom = 1;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		setOnModules("qua", qua);
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
			DiscordPresence.changePresence('Playing ${SONG.song}', ui.scoreText.text, null, true, FlxG.sound.music.length - Conductor.time);

		if (startedCountdown && startingSong && !paused)
		{
			// do not toggle update time as it will resync
			Conductor.time += elapsed * 1000;
		}

		if (startingSong && !paused)
		{
			if (startedCountdown && Conductor.time >= 0)
				startSong();
			else if (!startedCountdown)
				Conductor.time = -Conductor.crochet * 5;
		}

		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));

		if (Timings.health <= 0)
		{
			callOnModules('onGameOver', null);
			updateTime = persistentDraw = persistentUpdate = false;

			FlxG.sound.music.stop();
			DiscordPresence.changePresence("Game Over");
			TransitionState.switchState(new QuaverGameplay());
		}

		while ((ChartLoader.noteQueue[0] != null) && (ChartLoader.noteQueue[0].strumTime - Conductor.time) < 3500)
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

		if (FlxG.keys.justPressed.ONE)
			strums.botPlay = !strums.botPlay;

		holdNotes(elapsed);
		checkEventNote();

		callOnModules('onUpdatePost', elapsed);
	}

	override public function onActionPressed(action:ActionType)
	{
		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case PAUSE:
				if (canPause)
				{
					persistentUpdate = false;
					persistentDraw = true;
					openSubState(new PauseSubstate());
				}

			case RESET:
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
							var lastTime:Float = Conductor.time;
							Conductor.time = FlxG.sound.music.time;

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

							Conductor.time = lastTime;

							if (receptor.animation.curAnim.name != "confirm")
								receptor.playAnim('pressed');
						}
					}
				}
		}
		callOnModules('onKeyPress', action);
	}

	override public function onActionReleased(action:ActionType)
	{
		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case CONFIRM | BACK | RESET | PAUSE:
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
			controls.NOTE_LEFT.state == PRESSED,
			controls.NOTE_DOWN.state == PRESSED,
			controls.NOTE_UP.state == PRESSED,
			controls.NOTE_RIGHT.state == PRESSED
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
			if (FlxG.sound.music != null)
				FlxG.sound.music.pause();

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
				Conductor.resyncMusic();

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
		Conductor.time = 0;
		Conductor.time -= Conductor.crochet * 5;

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

		if (!stageBuild.skip.defaultCountdown)
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
			if (!stageBuild.skip.defaultCountdown && countdown >= 0 && countdown < introArray.length)
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
			if (!stageBuild.skip.defaultCountdown)
				FlxG.sound.play(soundsArray[countdown], 0.6);
		}, 5);
	}

	private function startSong()
	{
		startingSong = false;

		FlxG.sound.music.play();
		FlxG.sound.music.onComplete = endSong.bind();

		updateTime = true;

		setOnModules('songLength', FlxG.sound.music.length);
		callOnModules('onSongStart', null);
	}

	override public function beatHit(beat:Int)
	{
		super.beatHit(beat);

		if (curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}
	}

	private function noteHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			var hitObj:HitObject = getHitObjectByTime(note.strumTime);
			var receptor:Receptor = getReceptor(strums, note.noteData);
			note.wasGoodHit = true;
			note.judgement = Timings.judge(Math.abs(note.strumTime - Conductor.time), note.isSustain);
			receptor.playAnim('confirm', true);
			playHitObjectSound(hitObj);

			// quaver type shit (only count parent timing when hold ended kind of wacky tho)
			if (!note.isSustain && note.parent != note || note.isSustainEnd)
				ui.displayJudgement((!note.isSustain && note.parent != note) ? note.judgement : note.parent.judgement, (note.strumTime < Conductor.time));

			if (!note.isSustain && note.judgement == "sick")
				strums.generateSplash(receptor);

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
			var hitObj:HitObject = getHitObjectByTime(note.strumTime);
			var receptor:Receptor = getReceptor(strums, note.noteData);
			note.wasGoodHit = true;

			var time:Float = 0.15;
			if (note.isSustain && !note.isSustainEnd)
				time += 0.15;

			receptor.playAnim('confirm', true);
			receptor.holdTimer = time;
			playHitObjectSound(hitObj);

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
		FlxG.sound.music.stop();
		callOnModules('onEndSong', null);
		TransitionState.switchState(new funkin.states.SongSelection());
	}

	private function checkEventNote()
	{
		while (ChartLoader.eventQueue.length > 0)
		{
			var event:EventNote = ChartLoader.eventQueue[0];
			var leStrumTime:Float = event.strumTime;
			if (Conductor.time < leStrumTime)
				break;

			var module:ForeverModule = Events.loadedModules.get(event.event);

			var value1:String = "";
			if (event.value1 != null)
				value1 = event.value1;

			var value2:String = "";
			if (event.value2 != null)
				value2 = event.value2;

			try
			{
				if (module.exists("eventFunction"))
					module.get("eventFunction")(value1, value2);
			}
			catch (ex)
			{
				trace('Failed to execute event ($ex)');
			}

			callOnModules('onEventHit', event.event, value1, value2);
			ChartLoader.eventQueue.shift();
		}
	}

	// Helper bs

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];

	private function getHitObjectByTime(time:Float)
	{
		var retHitObj:HitObject = {
			StartTime: 0,
			Lane: 0,
			HitSound: null,
			EndTime: 0,
			KeySounds: null
		};

		for (i in 0...qua.HitObjects.length)
		{
			if (time >= qua.HitObjects[i].StartTime)
				retHitObj = qua.HitObjects[i];
		}

		return retHitObj;
	}

	// Having to add storage support is gonna be wild af
	private function playHitObjectSound(hitObject:HitObject)
	{
		if (hitObject.HitSound != null)
		{
			var targetSound:String = 'soft-hit${hitObject.HitSound.toLowerCase()}.wav';
			var targetPath:String = 'quaver:assets/quaver/${qua.MapSetId}/$targetSound'; // forgot to enforce when i was moving quaver to its own lib my bad
			FlxG.sound.play(Cache.getSound(targetPath), 0.4);
		}

		if (hitObject.KeySounds != null)
		{
			var targetPath:String = qua.CustomAudioSamples[hitObject.KeySounds.Sample - 1];
			FlxG.sound.play(Cache.getSound(targetPath), hitObject.KeySounds.Volume);
		}
	}
}
