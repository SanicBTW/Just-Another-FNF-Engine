package funkin.states;

import backend.Conductor;
import backend.DiscordPresence;
import backend.input.Controls.ActionType;
import backend.scripting.*;
import base.MusicBeatState;
import base.TransitionState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.ChartLoader;
import funkin.Events.EventNote;
import funkin.notes.Note;
import funkin.notes.Receptor;
import funkin.notes.StrumLine;
import funkin.substates.GameOverSubstate;
import funkin.substates.PauseSubstate;
import openfl.media.Sound;
import shaders.*;
import transitions.FadeTransition;

using StringTools;

// goofy code gotta order it bruh
class PlayState extends MusicBeatState
{
	// Cameras
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	// Camera target
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	// For the dynamic camera movement
	private var lastSection:Int = 0;
	private var camDisplaceX:Float = 0;
	private var camDisplaceY:Float = 0;
	private var camDisp:Float = 18;

	// Strum handling
	private var strumLines:FlxTypedGroup<StrumLine>;
	private var holdingLanes:Array<Bool> = [];

	public var playerStrums:StrumLine;
	public var opponentStrums:StrumLine;

	// Countdown
	public var startedCountdown:Bool = false;
	public var startingSong:Bool = false;

	private var startTimer:FlxTimer;

	// Stage, UI and characters
	private var stageBuild:Stage;

	private var ui:UI;

	public var boyfriendMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public var boyfriend:Character;
	public var gf:Character;
	public var dad:Character;

	// Pause handling
	public static var paused:Bool = false;
	public static var canPause:Bool = true;

	override public function create()
	{
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.stop();

		GameOverSubstate.resetVariables();
		Timings.call();
		Paths.music("tea-time");

		// dumb
		if (SongSelection.songSelected.isFS)
			ChartLoader.loadFSChart(SongSelection.songSelected.songName, SongSelection.songSelected.songDiff);
		else if (SongSelection.songSelected.netChart != null)
			ChartLoader.loadNetChart(SongSelection.songSelected.netChart, SongSelection.songSelected.netInst, SongSelection.songSelected.netVoices);
		else
			ChartLoader.loadChart(SongSelection.songSelected.songName, SongSelection.songSelected.songDiff);

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

		var separationX:Float = (FlxG.width / 4);
		var yPos:Float = (Settings.downScroll ? FlxG.height - (FlxG.height / 8) : (FlxG.height / 8));

		opponentStrums = new StrumLine((FlxG.width / 2) - separationX, yPos);
		opponentStrums.visible = !Settings.middleScroll;
		opponentStrums.botPlay = true;
		opponentStrums.onBotHit.add(botHit);
		strumLines.add(opponentStrums);

		playerStrums = new StrumLine(Settings.middleScroll ? (FlxG.width / 2) : (FlxG.width / 2) + separationX, yPos);
		playerStrums.onMiss.add(noteMiss);
		playerStrums.onBotHit.add(botHit);
		strumLines.add(playerStrums);

		add(strumLines);

		stageBuild = new Stage(SONG.stage);
		add(stageBuild);

		var positions:Stage.Positions = stageBuild.positions;
		boyfriendGroup = new FlxSpriteGroup(positions.boyfriend.x, positions.boyfriend.y);
		dadGroup = new FlxSpriteGroup(positions.opponent.x, positions.opponent.y);
		gfGroup = new FlxSpriteGroup(positions.girlfriend.x, positions.girlfriend.y);
		positions = null; // as its only a reference, making it null makes the var marked for gc i believe - thats on mark-and-sweep gc dummy

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		boyfriend = new Character(0, 0, true, SONG.player1);
		dad = new Character(0, 0, false, SONG.player2);

		if (!stageBuild.hide_girlfriend)
		{
			gf = new Character(0, 0, false, SONG.gfVersion);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dadGroup.add(dad);
		boyfriendGroup.add(boyfriend);

		ui = new UI();
		ui.cameras = [camHUD];
		add(ui);

		var gfOffset:Stage.Positions = stageBuild.camera_settings.offsets;
		var camPos:FlxPoint = new FlxPoint(gfOffset.girlfriend.x, gfOffset.girlfriend.y);
		gfOffset = null; // as its only a reference, making it null makes the var marked for gc i believe

		if (!stageBuild.hide_girlfriend)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition.x;
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition.y;
		}

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(gf.x, gf.y);
			if (!stageBuild.hide_girlfriend)
				gf.visible = false;
		}

		Conductor.time = -5000;

		camFollow = new FlxObject(camPos.x, camPos.y, 1, 1);
		camFollowPos = new FlxObject(camPos.x, camPos.y, 1, 1);

		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = (stageBuild != null) ? stageBuild.camera_settings.defaultZoom : 1;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		setOnModules('camFollow', camFollow);
		setOnModules('camFollowPos', camFollowPos);
		setOnModules('boyfriend', boyfriend);
		setOnModules('gf', gf);
		setOnModules('dad', dad);
		setOnModules('camGame', camGame);
		setOnModules('camHUD', camHUD);
		setOnModules('playerStrums', playerStrums);
		setOnModules('opponentStrums', opponentStrums);
		setOnModules('PlayState', this);
		setOnModules('UI', ui);
		setOnModules('stepHit', stepHit);
		setOnModules('beatHit', beatHit);
		setOnModules('moveCamera', moveCamera);
		setOnModules('moveCameraSection', moveCameraSection);

		startingSong = true;

		callOnModules('onCreatePost', '');
		for (event in ChartLoader.eventQueue)
		{
			callOnModules('initFunction', event.value1, event.value2);
		}

		setupCountdown();

		super.create();

		addTouchControls(HITBOX);

		FadeTransition.nextCamera = camOther;
	}

	override function update(elapsed:Float)
	{
		callOnModules('onUpdate', elapsed);

		var lerpVal:Float = FlxMath.bound(elapsed * 2.4 * stageBuild.camera_settings.speed, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		super.update(elapsed);

		if (!paused && !boyfriend.dead)
			DiscordPresence.changePresence('Playing ${SONG.song}', ui.scoreText.text, null, true, Conductor.boundInst.length - Conductor.time);

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

		FlxG.camera.zoom = FlxMath.lerp((stageBuild != null) ? stageBuild.camera_settings.defaultZoom : 1, FlxG.camera.zoom,
			FlxMath.bound(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));

		if (SONG.notes[Std.int(curStep / 16)] != null)
			updateCamTarget(elapsed);

		// death check
		doDeathCheck();

		while ((ChartLoader.noteQueue[0] != null) && (ChartLoader.noteQueue[0].strumTime - Conductor.time) < 3500)
		{
			var nextNote:Note = ChartLoader.noteQueue[0];
			if (nextNote != null)
			{
				var strumLine:StrumLine = strumLines.members[nextNote.strumLine];
				if (strumLine != null)
					strumLine.push(nextNote);
				else
				{
					// If we cant push to the targeted strum line, then we push to the current one and mark the note as must press so it  can be pressed lol
					nextNote.mustPress = true;
					playerStrums.push(nextNote);
				}
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
			playerStrums.botPlay = !playerStrums.botPlay;

		// quick pause method
		#if android
		if (FlxG.android.justPressed.BACK)
			onActionPressed(PAUSE);
		#end

		holdNotes(elapsed);
		checkEventNote();

		setOnModules('cameraX', camFollowPos.x);
		setOnModules('cameraY', camFollowPos.y);
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
				if (!playerStrums.botPlay && startedCountdown && !boyfriend.stunned && !paused)
				{
					for (receptor in playerStrums.receptors)
					{
						if (action == receptor.action)
						{
							var data:Int = receptor.noteData;
							holdingLanes[data] = true;

							var lastTime:Float = Conductor.time;
							Conductor.time = Conductor.boundInst.time;

							var possibleNotes:Array<Note> = [];
							var directionList:Array<Int> = [];
							var dumbNotes:Array<Note> = [];

							playerStrums.notesGroup.forEachAlive(function(daNote:Note)
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
								playerStrums.destroyNote(note);
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
				if (!playerStrums.botPlay && startedCountdown && !boyfriend.stunned && !paused)
				{
					for (receptor in playerStrums.receptors)
					{
						if (action == receptor.action)
						{
							holdingLanes[receptor.noteData] = false;
							receptor.playAnim('static');
						}
					}
				}
		}
		callOnModules('onKeyRelease', action);
	}

	private function holdNotes(elapsed:Float)
	{
		if (playerStrums == null || paused)
			return;

		if (!playerStrums.botPlay)
		{
			playerStrums.allNotes.forEachAlive(function(coolNote:Note)
			{
				if (holdingLanes[coolNote.noteData])
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

		if (boyfriend != null
			&& (!holdingLanes.contains(true) || playerStrums.botPlay)
			&& boyfriend.animation.curAnim != null
			&& boyfriend.holdTimer > Conductor.stepCrochet * (boyfriend.singDuration / 1000)
			&& boyfriend.animation.curAnim.name.startsWith("sing")
			&& !boyfriend.animation.curAnim.name.endsWith("miss"))
		{
			boyfriend.dance();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (!paused)
		{
			if (Conductor.boundInst != null)
			{
				Conductor.boundInst.pause();
				if (SONG.needsVoices)
					Conductor.boundVocals.pause();
			}

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
				Conductor.resyncFNF();

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
		for (strumline in strumLines)
		{
			for (receptor in strumline.receptors)
			{
				receptor.y -= 32;
				receptor.alpha = 0;
			}
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

		for (strumline in strumLines)
		{
			var i = 0;
			for (receptor in strumline.receptors)
			{
				FlxTween.tween(receptor, {y: receptor.initialY, alpha: receptor.setAlpha}, (Conductor.crochet * 4) / 1000,
					{ease: FlxEase.circOut, startDelay: (Conductor.crochet / 1000) + ((Conductor.stepCrochet / 1000) * i)});
				i++;
			}
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
			if (gf != null
				&& tmr.loopsLeft % gf.danceEveryNumBeats == 0
				&& gf.animation.curAnim.name != null
				&& !gf.animation.curAnim.name.startsWith("sing")
				&& !gf.stunned)
			{
				gf.dance();
			}

			if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0
				&& boyfriend.animation.curAnim != null
				&& !boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.stunned)
			{
				boyfriend.dance();
			}

			if (tmr.loopsLeft % dad.danceEveryNumBeats == 0
				&& dad.animation.curAnim != null
				&& !dad.animation.curAnim.name.startsWith('sing')
				&& !dad.stunned)
			{
				dad.dance();
			}

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

		Conductor.boundInst.play();
		Conductor.boundInst.onComplete = endSong.bind();

		Conductor.boundVocals.play();

		updateTime = true;

		setOnModules('songLength', Conductor.boundInst.length);
		callOnModules('onSongStart', null);
	}

	private function doDeathCheck()
	{
		// Ignore any health check!!!
		if (stageBuild.skip.healthCheck)
			return;

		if (Timings.health <= 0 && !boyfriend.dead)
		{
			boyfriend.stunned = boyfriend.dead = paused = true;
			updateTime = persistentDraw = persistentUpdate = false;

			if (SONG.needsVoices)
				Conductor.boundVocals.stop();
			Conductor.boundInst.stop();
			DiscordPresence.changePresence("Game Over");
			openSubState(new GameOverSubstate(boyfriend.x, boyfriend.y));
		}
	}

	override public function beatHit(beat:Int)
	{
		super.beatHit(beat);

		if (curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (!stageBuild.hide_girlfriend)
		{
			if (curBeat % gf.danceEveryNumBeats == 0 && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				gf.dance();
		}

		if (curBeat % boyfriend.danceEveryNumBeats == 0
			&& boyfriend.animation.curAnim != null
			&& !boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.stunned)
			boyfriend.dance();

		if (curBeat % dad.danceEveryNumBeats == 0
			&& dad.animation.curAnim != null
			&& !dad.animation.curAnim.name.startsWith('sing')
			&& !dad.stunned)
			dad.dance();
	}

	private function noteHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			var receptor:Receptor = getReceptor(playerStrums, note.noteData);
			note.wasGoodHit = true;

			// diff is already passed through Math.abs on judger
			var diff:Float = switch (Settings.diffStyle)
			{
				case TIME: (note.strumTime - Conductor.time);
				case HITBOX: receptor.getScreenPosition().distanceTo(note.getScreenPosition()); // single liner kinda messy ngl
			}

			var lateCond:Bool = switch (Settings.diffStyle)
			{
				case TIME: (note.strumTime < Conductor.time);
				case HITBOX: (note.getScreenPosition().y < receptor.getScreenPosition().y); // another single liner yikes
			}

			note.judgement = Timings.judge(diff, note.isSustain);
			receptor.playAnim('confirm', true);

			if (!note.isSustain)
				ui.displayJudgement(note.judgement, lateCond);

			if (!note.isSustain && note.judgement == "sick")
				playerStrums.generateSplash(receptor);

			var char:Character = boyfriend;
			if (!stageBuild.hide_girlfriend && note.gfNote)
				char = gf;

			characterSing(char, 'sing${receptor.getNoteDirection().toUpperCase()}');

			if (SONG.needsVoices)
				Conductor.boundVocals.volume = 1;

			callOnModules('goodNoteHit', [
				ChartLoader.noteQueue.indexOf(note),
				note.noteData,
				note.noteType,
				note.isSustain
			]);

			if (!note.isSustain)
				playerStrums.destroyNote(note);
		}
	}

	private function noteMiss(note:Note)
	{
		if (SONG.needsVoices)
			Conductor.boundVocals.volume = 0;

		// kind of dynamic stuff i guess
		var char:Character = boyfriend;
		if (!stageBuild.hide_girlfriend && note.gfNote)
			char = gf;

		if (char.hasMissAnimations && !char.curCharacter.contains("gf"))
			characterSing(char, 'sing${note.getNoteDirection().toUpperCase()}miss');

		if (!char.hasMissAnimations && char.curCharacter.contains("gf"))
			characterSing(char, "sad");

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
		var curStrums:StrumLine = (note.mustPress ? playerStrums : opponentStrums);
		var curChar:Character = (note.mustPress ? ((!stageBuild.hide_girlfriend && note.gfNote) ? gf : boyfriend) : dad);
		if (!note.wasGoodHit)
		{
			var receptor:Receptor = getReceptor(curStrums, note.noteData);
			note.wasGoodHit = true;

			if (SONG.needsVoices)
				Conductor.boundVocals.volume = 1;

			var time:Float = 0.15;
			if (note.isSustain && !note.isSustainEnd)
				time += 0.15;

			receptor.playAnim('confirm', true);
			receptor.holdTimer = time;

			if (!note.isSustain)
				curStrums.generateSplash(receptor);

			characterSing(curChar, 'sing${receptor.getNoteDirection().toUpperCase()}');

			callOnModules('${(curChar == boyfriend || curChar == gf) ? "goodNoteHit" : "opponentNoteHit"}', [
				ChartLoader.noteQueue.indexOf(note),
				note.noteData,
				note.noteType,
				note.isSustain
			]);

			if (!note.isSustain)
				curStrums.destroyNote(note);
			else
			{
				if (curChar != boyfriend)
					return;

				var targetHold:Float = Conductor.stepCrochet * (curChar.singDuration / 1000);
				if (curChar.holdTimer + 0.2 > targetHold)
					curChar.holdTimer = targetHold - 0.2;
			}
		}
	}

	// Had to change to Update Camera Style because Beats are delayed
	// Modified to add offsets and gf sections

	private function updateCamTarget(elapsed:Float)
	{
		var curSection = Std.int(curStep / 16);
		if (curSection != lastSection)
		{
			if (SONG.notes[lastSection] != null && (SONG.notes[curSection].mustHitSection != SONG.notes[lastSection].mustHitSection))
			{
				camDisplaceX = 0;
				camDisplaceY = 0;
				lastSection = Std.int(curStep / 16);
			}
		}

		updateCamFollow(elapsed);
		cameraDisplacement(boyfriend, true);
		cameraDisplacement(dad, false);
		if (SONG.notes[curSection].gfSection)
			cameraDisplacement(gf, SONG.notes[curSection].mustHitSection); // maybe a gf section is a must hit section???
	}

	private function updateCamFollow(?elapsed:Float)
	{
		if (elapsed == null)
			elapsed = FlxG.elapsed;

		var curSection = SONG.notes[Std.int(curStep / 16)];
		var mustHit:Bool = curSection.mustHitSection;

		var char:Character = (mustHit ? boyfriend : dad);
		if (curSection.gfSection)
			char = gf;

		var charCenterX:Float = char.getMidpoint().x;
		var charCenterY:Float = char.getMidpoint().y;

		var camOffsets:Stage.Positions = stageBuild.camera_settings.offsets;
		var offsetX:Float = (mustHit ? camOffsets.boyfriend.x : camOffsets.opponent.x);
		if (curSection.gfSection)
			offsetX = camOffsets.girlfriend.x;

		var offsetY:Float = (mustHit ? camOffsets.boyfriend.y : camOffsets.opponent.y);
		if (curSection.gfSection)
			offsetY = camOffsets.girlfriend.y;
		camOffsets = null; // as its only a reference, making it null makes the var marked for gc i believe

		var centerX = (mustHit ? charCenterX - 100 : charCenterX + 150);
		var centerY = (mustHit ? charCenterY - 100 : charCenterY - 100);
		var newX:Float = (mustHit ? (camDisplaceX - char.cameraPosition.x) - offsetX : (camDisplaceX + char.cameraPosition.x) + offsetX);
		var newY:Float = (camDisplaceY + char.cameraPosition.y) + offsetY;

		if (curSection.gfSection)
			camFollow.setPosition(charCenterX, charCenterY);
		else
			camFollow.setPosition(centerX, centerY);

		camFollow.x += newX;
		camFollow.y += newY;

		callOnModules('onMoveCamera', (curSection.gfSection ? 'gf' : (mustHit ? 'boyfriend' : 'dad')));
	}

	private function cameraDisplacement(character:Character, mustHit:Bool)
	{
		if (SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (SONG.notes[Std.int(curStep / 16)].mustHitSection
				&& mustHit
				|| (!SONG.notes[Std.int(curStep / 16)].mustHitSection && !mustHit))
			{
				if (character.animation.curAnim != null)
				{
					camDisplaceX = 0;
					camDisplaceY = 0;
					switch (character.animation.curAnim.name)
					{
						case 'singUP':
							camDisplaceY -= camDisp;
						case 'singDOWN':
							camDisplaceY += camDisp;
						case 'singLEFT':
							camDisplaceX -= camDisp;
						case 'singRIGHT':
							camDisplaceX += camDisp;
					}
				}
			}
		}
	}

	private function moveCameraSection(?id:Int = 0)
	{
		if (SONG.notes[id] == null || SONG.notes[lastSection] == null)
			return;

		if (id != lastSection)
		{
			if (SONG.notes[id].mustHitSection != SONG.notes[lastSection].mustHitSection)
			{
				camDisplaceX = 0;
				camDisplaceY = 0;
				lastSection = id;
			}
		}
		if (!stageBuild.hide_girlfriend && SONG.notes[id].gfSection)
		{
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition.x + stageBuild.camera_settings.offsets.girlfriend.x;
			camFollow.y += gf.cameraPosition.y + stageBuild.camera_settings.offsets.girlfriend.y;

			camDisplaceX = camFollow.x;
			camDisplaceY = camFollow.y;
			callOnModules('onMoveCamera', 'gf');
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			camDisplaceX = camFollow.x;
			camDisplaceY = camFollow.y;
			callOnModules('onMoveCamera', 'dad');
		}
		else
		{
			moveCamera(false);
			camDisplaceX = camFollow.x;
			camDisplaceY = camFollow.y;
			callOnModules('onMoveCamera', 'boyfriend');
		}
	}

	private function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition.x + stageBuild.camera_settings.offsets.opponent.x;
			camFollow.y += dad.cameraPosition.y + stageBuild.camera_settings.offsets.opponent.y;
		}
		else
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition.x - stageBuild.camera_settings.offsets.boyfriend.x;
			camFollow.y += boyfriend.cameraPosition.y + stageBuild.camera_settings.offsets.boyfriend.y;
		}
	}

	private function endSong():Void
	{
		updateTime = false;
		Conductor.boundInst.stop();
		Conductor.boundVocals.stop();
		callOnModules('onEndSong', null);
		TransitionState.switchState(new SongSelection());
	}

	private function characterSing(char:Character, anim:String)
	{
		if (char == null)
			return;

		char.playAnim(anim, true);
		char.holdTimer = 0;
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

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];
}
