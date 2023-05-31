package funkin.states;

import Paths.Libraries;
import backend.Cache;
import backend.Controls;
import base.Conductor;
import base.MusicBeatState;
import base.ScriptableState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.ChartLoader;
import funkin.notes.Note;
import funkin.notes.Receptor;
import funkin.notes.StrumLine;
import lime.graphics.Image;
import lime.utils.Assets;
import network.Request;
import network.pocketbase.Collection;
import network.pocketbase.Record;
import openfl.display.BitmapData;
import openfl.media.Sound;
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
	private var camMov:Float = 8;

	private var bfTurn:Bool = false;

	// Strum handling
	private var strumLines:FlxTypedGroup<StrumLine>;

	public var playerStrums:StrumLine;
	public var opponentStrums:StrumLine;

	// Countdown
	public var startedCountdown:Bool = false;
	public var startingSong:Bool = false;

	private var startTimer:FlxTimer;

	// Stage, UI and characters
	private var stageBuild:Stage;

	private var ui:UI;

	private var player:Character;
	private var girlfriend:Character;
	private var opponent:Character;

	// Them input
	private final actionList:Array<Action> = [Action.NOTE_LEFT, Action.NOTE_DOWN, Action.NOTE_UP, Action.NOTE_RIGHT];

	override public function create()
	{
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.stop();

		// dumb
		if (SongSelection.songSelected.isFS)
			ChartLoader.loadFSChart(SongSelection.songSelected.songName);
		else if (SongSelection.songSelected.netChart != null)
			ChartLoader.loadNetChart(SongSelection.songSelected.netChart, SongSelection.songSelected.netInst, SongSelection.songSelected.netVoices);
		else
			ChartLoader.loadChart(SongSelection.songSelected.songName, SongSelection.songSelected.songDiff);

		Controls.targetActions = NOTES;
		Timings.call();

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

		var separation:Float = FlxG.width / 4;

		opponentStrums = new StrumLine((FlxG.width / 2) - separation, FlxG.height / 6);
		opponentStrums.botPlay = true;
		opponentStrums.onBotHit.add(botHit);
		strumLines.add(opponentStrums);

		playerStrums = new StrumLine((FlxG.width / 2) + separation, FlxG.height / 6);
		playerStrums.onMiss.add(noteMiss);
		strumLines.add(playerStrums);

		add(strumLines);

		stageBuild = new Stage(SONG.stage);
		add(stageBuild);

		player = new Character(stageBuild.boyfriend[0], stageBuild.boyfriend[1], true, SONG.player1);
		opponent = new Character(stageBuild.opponent[0], stageBuild.opponent[1], false, SONG.player2);

		if (!stageBuild.hide_girlfriend)
		{
			girlfriend = new Character(stageBuild.girlfriend[0], stageBuild.girlfriend[1], false, SONG.gfVersion);
			girlfriend.scrollFactor.set(0.95, 0.95);
			add(girlfriend);
		}

		add(opponent);
		add(player);

		ui = new UI();
		ui.cameras = [camHUD];
		add(ui);

		var camPos:FlxPoint = new FlxPoint(stageBuild.camera_girlfriend[0], stageBuild.camera_girlfriend[1]);

		if (!stageBuild.hide_girlfriend)
		{
			camPos.x += girlfriend.getGraphicMidpoint().x + girlfriend.cameraPosition.x;
			camPos.y += girlfriend.getGraphicMidpoint().y + girlfriend.cameraPosition.y;
		}

		if (opponent.curCharacter.startsWith('gf'))
		{
			opponent.setPosition(girlfriend.x, girlfriend.y);
			if (!stageBuild.hide_girlfriend)
				girlfriend.visible = false;
		}

		Conductor.songPosition = -5000;

		camFollow = new FlxObject(camPos.x, camPos.y, 1, 1);
		camFollowPos = new FlxObject(camPos.x, camPos.y, 1, 1);

		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = (stageBuild != null) ? stageBuild.defaultCamZoom : 1;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		setOnModules('camFollow', camFollow);
		setOnModules('camFollowPos', camFollowPos);
		setOnModules('boyfriend', player);
		setOnModules('gf', girlfriend);
		setOnModules('dad', opponent);
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

		setupCountdown();

		super.create();

		FadeTransition.nextCamera = camOther;
	}

	override function update(elapsed:Float)
	{
		callOnModules('onUpdate', elapsed);

		var lerpVal:Float = FlxMath.bound(elapsed * 2.4 * stageBuild.camera_speed, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		super.update(elapsed);

		if (startedCountdown && startingSong)
		{
			// do not toggle update time as it will resync
			Conductor.songPosition += elapsed * 1000;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if (!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}

		FlxG.camera.zoom = FlxMath.lerp((stageBuild != null) ? stageBuild.defaultCamZoom : 1, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));

		while ((ChartLoader.noteQueue[0] != null) && (ChartLoader.noteQueue[0].strumTime - Conductor.songPosition) < 3500)
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

		holdNotes(elapsed);

		setOnModules('cameraX', camFollowPos.x);
		setOnModules('cameraY', camFollowPos.y);
		callOnModules('onUpdatePost', elapsed);
	}

	override private function onActionPressed(action:String)
	{
		if (startingSong)
			return;

		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case "reset" | "confirm":
				return;

			case "back":
				Conductor.boundInst.onComplete();

			default:
				if (!playerStrums.botPlay && startedCountdown && !player.stunned)
				{
					for (receptor in playerStrums.receptors)
					{
						if (action == receptor.action)
						{
							var data:Int = receptor.noteData;
							var lastTime:Float = Conductor.songPosition;
							Conductor.songPosition = Conductor.boundInst.time;

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
								trace("Killing dumb note");
								playerStrums.destroyNote(note);
							}

							if (possibleNotes.length > 0)
							{
								for (coolNote in possibleNotes)
								{
									if (coolNote.canBeHit && !coolNote.tooLate)
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

	override private function onActionReleased(action:String)
	{
		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case "confirm" | "back" | "reset":
				return;

			default:
				if (!playerStrums.botPlay && startedCountdown)
				{
					for (receptor in playerStrums.receptors)
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
		if (playerStrums == null)
			return;

		var holdArray:Array<Bool> = parseKeys();

		if (!playerStrums.botPlay)
		{
			playerStrums.allNotes.forEachAlive(function(coolNote:Note)
			{
				if (holdArray[coolNote.noteData])
				{
					if ((coolNote.parent != null && coolNote.parent.wasGoodHit)
						&& coolNote.canBeHit
						&& !coolNote.tooLate
						&& !coolNote.wasGoodHit
						&& coolNote.isSustain)
					{
						noteHit(coolNote);
					}
				}
			});
		}

		if (player != null
			&& (player.holdTimer > Conductor.stepCrochet * (player.singDuration / 1000)
				&& (!holdArray.contains(true) || playerStrums.botPlay)))
		{
			if (player.animation.curAnim.name.startsWith("sing") && !player.animation.curAnim.name.endsWith("miss"))
				player.dance();
		}
	}

	private function parseKeys():Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...actionList.length)
		{
			ret[i] = Controls.isActionPressed(actionList[i]);
		}
		return ret;
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
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

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
			if (girlfriend != null
				&& tmr.loopsLeft % girlfriend.danceEveryNumBeats == 0
				&& girlfriend.animation.curAnim.name != null
				&& !girlfriend.animation.curAnim.name.startsWith("sing")
				&& !girlfriend.stunned)
			{
				girlfriend.dance();
			}

			if (tmr.loopsLeft % player.danceEveryNumBeats == 0
				&& player.animation.curAnim != null
				&& !player.animation.curAnim.name.startsWith('sing')
				&& !player.stunned)
			{
				player.dance();
			}

			if (tmr.loopsLeft % opponent.danceEveryNumBeats == 0
				&& opponent.animation.curAnim != null
				&& !opponent.animation.curAnim.name.startsWith('sing')
				&& !opponent.stunned)
			{
				opponent.dance();
			}

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

		Conductor.boundVocals.play();

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

		if (SONG.notes[Std.int(curStep / 16)] != null && Conductor.boundInst.playing)
			moveCameraSection(Std.int(curStep / 16));

		if (FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (!stageBuild.hide_girlfriend)
		{
			if (curBeat % girlfriend.danceEveryNumBeats == 0
				&& !girlfriend.animation.curAnim.name.startsWith("sing")
				&& !girlfriend.stunned)
				girlfriend.dance();
		}

		if (curBeat % player.danceEveryNumBeats == 0
			&& player.animation.curAnim != null
			&& !player.animation.curAnim.name.startsWith('sing')
			&& !player.stunned)
			player.dance();

		if (curBeat % opponent.danceEveryNumBeats == 0
			&& opponent.animation.curAnim != null
			&& !opponent.animation.curAnim.name.startsWith('sing')
			&& !opponent.stunned)
			opponent.dance();

		setOnModules('curBeat', curBeat);
		callOnModules('onBeatHit', []);
	}

	private function noteHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			var receptor:Receptor = getReceptor(playerStrums, note.noteData);
			note.wasGoodHit = true;
			receptor.playAnim('confirm', true);

			if (!note.isSustain)
				Timings.judge(-(note.strumTime - Conductor.songPosition));

			characterSing(player, 'sing${receptor.getNoteDirection().toUpperCase()}');

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

			ui.updateText();
		}
	}

	private function noteMiss(note:Note)
	{
		if (SONG.needsVoices)
			Conductor.boundVocals.volume = 0;

		characterSing(player, 'sing${note.getNoteDirection().toUpperCase()}miss');

		Timings.judge(Timings.judgements[Timings.judgements.length - 1].timing);

		callOnModules('noteMiss', [
			ChartLoader.noteQueue.indexOf(note),
			note.noteData,
			note.noteType,
			note.isSustain
		]);
		ui.updateText();
	}

	private function botHit(note:Note)
	{
		var curStrums:StrumLine = (note.mustPress ? playerStrums : opponentStrums);
		var curChar:Character = (note.mustPress ? player : opponent);
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

			characterSing(curChar, 'sing${receptor.getNoteDirection().toUpperCase()}');

			callOnModules('${curChar == player ? "goodNoteHit" : "opponentNoteHit"}', [
				ChartLoader.noteQueue.indexOf(note),
				note.noteData,
				note.noteType,
				note.isSustain
			]);

			if (!note.isSustain)
				curStrums.destroyNote(note);
			else
			{
				if (curChar != player)
					return;

				var targetHold:Float = Conductor.stepCrochet * (curChar.singDuration / 1000);
				if (curChar.holdTimer + 0.2 > targetHold)
					curChar.holdTimer = targetHold - 0.2;
			}
		}
	}

	// camera movements are mostly from my scarlet melopoeia port lol

	function moveCameraSection(?id:Int = 0):Void
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
			camFollow.setPosition(girlfriend.getMidpoint().x, girlfriend.getMidpoint().y);
			camFollow.x += girlfriend.cameraPosition.x + stageBuild.camera_girlfriend[0];
			camFollow.y += girlfriend.cameraPosition.y + stageBuild.camera_girlfriend[1];

			camDisplaceX = camFollow.x;
			camDisplaceY = camFollow.y;
			bfTurn = false;
			callOnModules('onMoveCamera', 'gf');
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			camDisplaceX = camFollow.x;
			camDisplaceY = camFollow.y;
			bfTurn = false;
			callOnModules('onMoveCamera', 'dad');
		}
		else
		{
			moveCamera(false);
			camDisplaceX = camFollow.x;
			camDisplaceY = camFollow.y;
			bfTurn = true;
			callOnModules('onMoveCamera', 'boyfriend');
		}
	}

	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.setPosition(opponent.getMidpoint().x + 150, opponent.getMidpoint().y - 100);
			camFollow.x += opponent.cameraPosition.x + stageBuild.camera_opponent[0];
			camFollow.y += opponent.cameraPosition.y + stageBuild.camera_opponent[1];
		}
		else
		{
			camFollow.setPosition(player.getMidpoint().x - 100, player.getMidpoint().y - 100);
			camFollow.x -= player.cameraPosition.x - stageBuild.camera_boyfriend[0];
			camFollow.y += player.cameraPosition.y + stageBuild.camera_boyfriend[1];
		}
	}

	// what the fuck is this
	function cameraMovement(animToPlay, isDad)
	{
		switch (animToPlay)
		{
			case 'singLEFT':
				if ((!bfTurn && isDad) || (bfTurn && !isDad))
				{
					camFollow.x = camDisplaceX - camMov;
					camFollow.y = camDisplaceY;
				}
			case "singDOWN":
				if (((!bfTurn && isDad) || (bfTurn && !isDad)))
				{
					camFollow.x = camDisplaceX;
					camFollow.y = camDisplaceY + camMov;
				}
			case "singUP":
				if (((!bfTurn && isDad) || (bfTurn && !isDad)))
				{
					camFollow.x = camDisplaceX;
					camFollow.y = camDisplaceY - camMov;
				}
			case "singRIGHT":
				if (((!bfTurn && isDad) || (bfTurn && !isDad)))
				{
					camFollow.x = camDisplaceX + camMov;
					camFollow.y = camDisplaceY;
				}
		}
	}

	private function endSong():Void
	{
		updateTime = false;
		Conductor.boundInst.stop();
		Conductor.boundVocals.stop();
		callOnModules('onEndSong', null);
		ScriptableState.switchState(new SongSelection());
	}

	private function characterSing(char:Character, anim:String)
	{
		if (char == null)
			return;

		cameraMovement(anim, char == opponent);
		char.playAnim(anim, true);
		char.holdTimer = 0;
	}

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];
}
