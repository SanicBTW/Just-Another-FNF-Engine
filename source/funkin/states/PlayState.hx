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
import flixel.util.FlxColor;
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

class PlayState extends MusicBeatState
{
	// Cameras
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	// Camera target
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	// Strum handling
	private var strumLines:FlxTypedGroup<StrumLine>;

	public var playerStrums:StrumLine;
	public var opponentStrums:StrumLine;

	// Stage, UI and characters
	public static var stageBuild:Stage;

	private var player:Character;
	private var opponent:Character;

	var actionList:Array<Action> = [Action.NOTE_LEFT, Action.NOTE_DOWN, Action.NOTE_UP, Action.NOTE_RIGHT];

	private var conductorTracking:FlxText;

	var lastSection:Int = 0;
	var campointX:Float = 0;
	var campointY:Float = 0;
	var bfturn:Bool = false;
	var mult = 8;

	override public function create()
	{
		ChartLoader.loadChart(SongSelection.songSelected.songName, SongSelection.songSelected.songDiff);
		Controls.targetActions = NOTES;

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

		add(opponent);
		add(player);

		setOnModules('boyfriend', player);
		setOnModules('dad', opponent);
		setOnModules('camGame', camGame);
		setOnModules('camHUD', camHUD);
		setOnModules('playerStrums', playerStrums);
		setOnModules('opponentStrums', opponentStrums);

		conductorTracking = new FlxText(15, 15, 0, 'Steps: ?\n Beats: ?\nBPM: ${Conductor.bpm}', 24);
		conductorTracking.setFormat(Paths.font('vcr.ttf'), 24);
		conductorTracking.cameras = [camHUD];
		add(conductorTracking);

		var camPos:FlxPoint = new FlxPoint(player.x + (player.width / 2), player.y + (player.height / 2));

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);

		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = (stageBuild != null) ? stageBuild.defaultCamZoom : 1;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection(0);

		setOnModules('camFollow', camFollow);
		setOnModules('camFollowPos', camFollowPos);

		callOnModules('onCreatePost', '');

		super.create();

		FadeTransition.nextCamera = camOther;

		Conductor.boundInst.onComplete = () ->
		{
			ScriptableState.switchState(new SongSelection());
		}
	}

	override function update(elapsed:Float)
	{
		var lerpVal:Float = FlxMath.bound(elapsed * 2.4, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

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
			}
			ChartLoader.noteQueue.splice(ChartLoader.noteQueue.indexOf(nextNote), 1);
		}

		conductorTracking.text = 'Steps: ${curStep}\nBeats: ${curBeat}\nBPM: ${Conductor.bpm}';
		super.update(elapsed);

		holdNotes(elapsed);
	}

	override private function onActionPressed(action:String)
	{
		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case "reset":
				return;

			case "back":
				Conductor.boundInst.stop();
				Conductor.boundVocals.stop();
				ScriptableState.switchState(new SongSelection());

			case "confirm":
				Conductor.boundInst.play();

			default:
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
										if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
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

	override private function onActionReleased(action:String)
	{
		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case "confirm" | "back" | "reset":
				return;

			default:
				for (receptor in playerStrums.receptors)
				{
					if (action == receptor.action)
					{
						receptor.playAnim('static');
					}
				}
		}
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

	override public function stepHit()
	{
		super.stepHit();

		setOnModules('curStep', curStep);
		callOnModules('onStepHit', []);
	}

	override public function beatHit()
	{
		if (SONG.notes[Std.int(curStep / 16)] != null && Conductor.boundInst.playing)
		{
			moveCameraSection(Std.int(curStep / 16));
		}

		if (FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (curBeat % player.danceEveryNumBeats == 0 && !player.animation.curAnim.name.startsWith("sing"))
			player.dance();
		if (curBeat % opponent.danceEveryNumBeats == 0 && !opponent.animation.curAnim.name.startsWith("sing"))
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

			characterSing(player, 'sing${receptor.getNoteDirection().toUpperCase()}');

			if (SONG.needsVoices)
				Conductor.boundVocals.volume = 1;

			if (!note.isSustain)
				playerStrums.destroyNote(note);
		}
	}

	private function noteMiss(note:Note)
	{
		if (SONG.needsVoices)
			Conductor.boundVocals.volume = 0;

		var receptor:Receptor = getReceptor(playerStrums, note.noteData);
		characterSing(player, 'sing${receptor.getNoteDirection().toUpperCase()}miss');
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

	function moveCameraSection(?id:Int = 0):Void
	{
		if (id != lastSection)
		{
			if (SONG.notes[lastSection] != null && (SONG.notes[id].mustHitSection != SONG.notes[lastSection].mustHitSection))
			{
				campointX = 0;
				campointY = 0;
				lastSection = id;
			}
		}

		if (SONG.notes[id] != null && camFollow.x != opponent.getMidpoint().x + 150 && !SONG.notes[id].mustHitSection)
		{
			callOnModules('onMoveCamera', 'dad');

			moveCamera(true);
			campointX = camFollow.x;
			campointY = camFollow.y;
			bfturn = false;
		}

		if (SONG.notes[id] != null && SONG.notes[id].mustHitSection && camFollow.x != player.getMidpoint().x - 100)
		{
			callOnModules('onMoveCamera', 'bf');

			moveCamera(false);
			campointX = camFollow.x;
			campointY = camFollow.y;
			bfturn = true;
		}
	}

	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.setPosition(opponent.getMidpoint().x + 150, opponent.getMidpoint().y - 100);
			camFollow.x += opponent.cameraPosition.x;
			camFollow.y += opponent.cameraPosition.y;
		}
		else
		{
			camFollow.setPosition(player.getMidpoint().x - 100, player.getMidpoint().y - 100);
			camFollow.x -= player.cameraPosition.x;
			camFollow.y += player.cameraPosition.y;
		}
	}

	function cameraShit(animToPlay, isDad)
	{
		switch (animToPlay)
		{
			case 'singLEFT':
				if ((!bfturn && isDad) || (bfturn && !isDad))
				{
					camFollow.x = campointX - mult;
					camFollow.y = campointY;
				}
			case "singDOWN":
				if (((!bfturn && isDad) || (bfturn && !isDad)))
				{
					camFollow.x = campointX;
					camFollow.y = campointY + mult;
				}
			case "singUP":
				if (((!bfturn && isDad) || (bfturn && !isDad)))
				{
					camFollow.x = campointX;
					camFollow.y = campointY - mult;
				}
			case "singRIGHT":
				if (((!bfturn && isDad) || (bfturn && !isDad)))
				{
					camFollow.x = campointX + mult;
					camFollow.y = campointY;
				}
		}
	}

	private function characterSing(char:Character, anim:String)
	{
		if (char == null)
			return;

		cameraShit(anim, char == opponent);
		char.playAnim(anim, true);
		char.holdTimer = 0;
	}

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];
}
