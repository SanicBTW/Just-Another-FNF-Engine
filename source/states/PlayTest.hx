package states;

import base.Conductor;
import base.Controls;
import base.FadeTransition;
import base.MusicBeatState;
import base.ScriptableState.ScriptableSubState;
import base.ScriptableState;
import base.SoundManager.AudioStream;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.Character;
import funkin.ChartLoader;
import funkin.CoolUtil;
import funkin.Ratings;
import funkin.Stage;
import funkin.notes.Note;
import funkin.notes.Receptor;
import funkin.notes.StrumLine;
import funkin.ui.UI;
import openfl.filters.ShaderFilter;
import openfl.media.Sound;
import shader.*;
import shader.ChromaticAberration.ChromaticAbberationShader;
import substates.PauseState;

using StringTools;

class PlayTest extends MusicBeatState
{
	// public static var stage:Stage;
	public var camHUD:FlxCamera;
	public var camHUD2:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	var strumLines:FlxTypedGroup<StrumLine>;

	private var opponentStrums:StrumLine;

	public var playerStrums:StrumLine;

	public var downscroll:Bool = false;

	private var generatedMusic:Bool = false;

	private var player:Character;
	private var opponent:Character;

	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	private var lastSection:Int = 0;
	private var camDisplaceX:Float = 0;
	private var camDisplaceY:Float = 0;

	private var hud:UI;

	public static var paused:Bool = false;
	public static var canPause:Bool = true;

	public static var instance:PlayTest;

	var shad:ChromaticAbberationShader = new ChromaticAbberationShader();

	override function create()
	{
		Controls.setActions(NOTES);
		Ratings.call();

		instance = this;

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		camGame.bgColor = FlxColor.GRAY;
		FlxCamera.defaultCameras = [camGame];

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther);

		strumLines = new FlxTypedGroup<StrumLine>();
		var separation:Float = FlxG.width / 4;
		opponentStrums = new StrumLine((FlxG.width / 2) - separation, 4);
		opponentStrums.onBotHit.add(opponentHit);
		strumLines.add(opponentStrums);
		playerStrums = new StrumLine((FlxG.width / 2) + separation, 4);
		playerStrums.onBotHit.add(playerBotHit);
		strumLines.add(playerStrums);
		add(strumLines);
		strumLines.cameras = [camHUD];

		/*
			stage = new Stage("stage");
			add(stage); */

		player = new Character(750, 100, true, "bf");
		add(player);

		opponent = new Character(50, 100, false, "dad");
		add(opponent);

		Conductor.songPosition = -5000;

		hud = new UI();
		add(hud);
		hud.cameras = [camHUD];

		generateSong();

		/*
			var shaderFilt:ShaderFilter = new ShaderFilter(shad);
			FlxG.camera.setFilters([shaderFilt]); */

		var camPos:FlxPoint = new FlxPoint(player.x + (player.width / 2), player.y + (player.height / 2));

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);

		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = /*stage.cameraZoom*/ 0.7;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		super.create();

		Paths.music("tea-time"); // precache the sound lol
		FadeTransition.nextCamera = camOther;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// shad.elapsed.value = [FlxG.game.ticks / 1000];

		var lerpVal:Float = (elapsed * 2.4);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		FlxG.camera.zoom = FlxMath.lerp(/*stage.cameraZoom*/ 0.7, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));

		if (generatedMusic && SONG.notes[Std.int(curStep / 16)] != null)
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
			cameraDisplacement(player, true);
			cameraDisplacement(opponent, false);

			parseEventColumn(ChartLoader.unspawnedNoteList, function(unspawnNote:Note)
			{
				var strumLine:StrumLine = strumLines.members[unspawnNote.strumLine];
				if (strumLine != null)
					strumLine.push(unspawnNote);
			}, -(16 * Conductor.stepCrochet));

			playerStrums.holdGroup.forEachAlive(function(coolNote:Note)
			{
				if (coolNote.isSustain && coolNote.canBeHit && keys[coolNote.noteData])
				{
					playerHit(coolNote);
				}
			});

			if (player != null
				&& (player.holdTimer > (Conductor.stepCrochet * player.singDuration) / 1000)
				&& (!keys.contains(true) || playerStrums.botPlay))
			{
				if (player.animation.curAnim.name.startsWith("sing") && !player.animation.curAnim.name.endsWith("miss"))
					player.dance();
			}
		}
	}

	// kade way
	private static var receptorActionList:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	private var keys:Array<Bool> = [false, false, false, false];

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (action == "confirm" && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			openSubState(new PauseState());
			return;
		}

		if (playerStrums.botPlay)
			return;

		var data:Int = -1;

		if (receptorActionList.contains(action))
			data = receptorActionList.indexOf(action);
		else
			return;

		if (keys[data])
		{
			trace('already holding $action');
			return;
		}

		keys[data] = true;

		var possibleNoteList:Array<Note> = [];
		var pressedNotes:Array<Note> = [];

		playerStrums.notesGroup.forEachAlive(function(daNote:Note)
		{
			if ((daNote.noteData == data) && !daNote.isSustain && daNote.canBeHit && !daNote.tooLate)
				possibleNoteList.push(daNote);
		});
		possibleNoteList.sort((a, b) -> Std.int(a.stepTime - b.stepTime));

		if (possibleNoteList.length > 0)
		{
			var eligable:Bool = true;
			var firstNote:Bool = true;
			for (coolNote in possibleNoteList)
			{
				for (noteDouble in pressedNotes)
				{
					if (Math.abs(noteDouble.stepTime - coolNote.stepTime) < 0.1)
						firstNote = false;
					else
						eligable = false;
				}

				if (eligable)
				{
					playerHit(coolNote);
					pressedNotes.push(coolNote);
				}
			}
		}

		if (getReceptor(playerStrums, data).animation.curAnim.name != "confirm")
			getReceptor(playerStrums, data).playAnim('pressed');
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);

		var data:Int = -1;

		if (receptorActionList.contains(action))
			data = receptorActionList.indexOf(action);
		else
			return;

		keys[data] = false;

		getReceptor(playerStrums, data).playAnim('static');
	}

	override public function beatHit()
	{
		super.beatHit();

		if (curBeat % 2 == 0)
		{
			if (player.animation.curAnim.name.startsWith("idle") || player.animation.curAnim.name.startsWith("dance"))
				player.dance();
			if (opponent.animation.curAnim.name.startsWith("idle") || opponent.animation.curAnim.name.startsWith("dance"))
				opponent.dance();
		}

		if (curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.05;
		}

		/*
			if (SONG.notes[Std.int(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Std.int(curStep / 16)].bpm);
		}*/
	}

	private function opponentHit(note:Note)
	{
		if (SONG.needsVoices)
			Conductor.boundVocals.audioVolume = 1;

		var time:Float = 0.15;
		if (note.isSustain && !note.isSustainEnd)
			time += 0.15;
		receptorPlayAnim(true, note.noteData, time);

		if (!note.doubleNote)
		{
			opponent.playAnim('sing${Receptor.getArrowFromNum(note.noteData).toUpperCase()}', true);
			opponent.holdTimer = 0;
		}
		else
			trail(opponent, note);

		if (note.doubleNote && note.isSustain && opponent.animation.curAnim.name == "idle")
		{
			opponent.playAnim('sing${Receptor.getArrowFromNum(note.noteData).toUpperCase()}', true);
			opponent.holdTimer = 0;
		}

		if (!note.isSustain)
			destroyNote(opponentStrums, note);
		else
		{
			var targetHold:Float = (Conductor.stepCrochet * opponent.singDuration) / 1000;
			if (opponent.holdTimer + 0.2 > targetHold)
				opponent.holdTimer = targetHold - 0.2;
		}
	}

	private function playerHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			getReceptor(playerStrums, note.noteData).playAnim('confirm');

			if (!note.isSustain)
			{
				var noteDiff:Float = Math.abs((note.stepTime * Conductor.stepCrochet) - Conductor.songPosition);
				Ratings.updateAccuracy(Ratings.judgements[Ratings.judge(noteDiff)][1]);
				if (note.children.length > 0)
					Ratings.notesHit++;
			}
			else
			{
				if (note.parent != null)
					Ratings.updateAccuracy(100, true, note.parent.children.length);
			}

			if (!note.doubleNote)
			{
				player.playAnim('sing${Receptor.getArrowFromNum(note.noteData).toUpperCase()}', true);
				player.holdTimer = 0;
			}
			else
				trail(player, note);

			note.wasGoodHit = true;
			if (SONG.needsVoices)
				Conductor.boundVocals.audioVolume = 1;

			if (!note.isSustain)
				destroyNote(playerStrums, note);
		}
	}

	// fix
	private function playerBotHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			var time:Float = 0.15;
			if (note.isSustain && !note.isSustainEnd)
				time += 0.15;
			receptorPlayAnim(false, note.noteData, time);

			if (!note.doubleNote)
			{
				player.playAnim('sing${Receptor.getArrowFromNum(note.noteData).toUpperCase()}', true);
				player.holdTimer = 0;
			}
			else
				trail(player, note);

			note.wasGoodHit = true;
			if (SONG.needsVoices)
				Conductor.boundVocals.audioVolume = 1;

			if (!note.isSustain)
				destroyNote(playerStrums, note);
			else
			{
				var targetHold:Float = (Conductor.stepCrochet * player.singDuration) / 1000;
				if (player.holdTimer + 0.2 > targetHold)
					player.holdTimer = targetHold - 0.2;
			}
		}
	}

	private function playerMissPress(direction:Int = 1)
	{
		if (SONG.needsVoices)
			Conductor.boundVocals.audioVolume = 0;

		player.playAnim('sing${Receptor.getArrowFromNum(direction).toUpperCase()}miss', true);

		Ratings.misses++;
		Ratings.updateAccuracy(Ratings.judgements.get("miss")[1]);
	}

	private function receptorPlayAnim(opponent:Bool, noteData:Int, time:Float)
	{
		var receptor:Receptor = getReceptor(opponent ? opponentStrums : playerStrums, noteData);
		if (receptor != null)
		{
			receptor.playAnim('confirm', true);
			receptor.resetAnim = time;
		}
	}

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];

	private function destroyNote(strumLine:StrumLine, note:Note)
	{
		note.active = false;
		note.exists = false;

		note.kill();
		strumLine.allNotes.remove(note, true);
		(note.isSustain ? strumLine.holdGroup.remove(note, true) : strumLine.notesGroup.remove(note, true));
		note.destroy();
	}

	public function parseEventColumn(eventColumn:Array<Dynamic>, functionToCall:Dynamic->Void, ?timeDelay:Float = 0)
	{
		// check if there even are events to begin with
		if (eventColumn.length > 0)
		{
			while (eventColumn[0] != null && (eventColumn[0].stepTime + timeDelay / Conductor.stepCrochet) <= Conductor.stepPosition)
			{
				if (functionToCall != null)
					functionToCall(eventColumn[0]);
				eventColumn.splice(eventColumn.indexOf(eventColumn[0]), 1);
			}
		}
	}

	private function updateCamFollow(?elapsed:Float)
	{
		if (elapsed == null)
			elapsed = FlxG.elapsed;

		var mustHit:Bool = SONG.notes[Std.int(curStep / 16)].mustHitSection;
		var char:Character = (mustHit ? player : opponent);
		var charCenterX:Float = char.getMidpoint().x;
		var charCenterY:Float = char.getMidpoint().y;

		var centerX = (mustHit ? charCenterX - 100 : charCenterX + 150);
		var centerY = (mustHit ? charCenterY - 100 : charCenterY - 100);
		var newX:Float = (mustHit ? (camDisplaceX - char.cameraPosition.x) : (camDisplaceX + char.cameraPosition.x));
		var newY:Float = camDisplaceY + char.cameraPosition.y;

		camFollow.setPosition(centerX, centerY);
		camFollow.x += newX;
		camFollow.y += newY;
	}

	var camDisp:Float = 15;

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

	private function generateSong():Void
	{
		SONG = ChartLoader.loadChart(this, "", 2);
		Conductor.mapBPMChanges(SONG);
		for (strumLine in strumLines)
		{
			strumLine.lineSpeed = SONG.speed;
		}

		generatedMusic = true;

		Conductor.boundSong.onFinish.add(() ->
		{
			Conductor.boundSong.stop();
			Conductor.boundVocals.stop();
			ChartLoader.netInst = null;
			ChartLoader.netVoices = null;
			ScriptableState.switchState(new MainState());
		});
		Conductor.boundSong.play();
		if (SONG.needsVoices)
			Conductor.boundVocals.play();
		Conductor.resyncTime();
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (!paused)
		{
			if (Conductor.boundSong != null)
				Conductor.boundSong.stop();
			if (Conductor.boundVocals != null)
				Conductor.boundVocals.stop();

			paused = true;
			canPause = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (Conductor.boundSong != null)
				Conductor.boundSong.play();
			if (Conductor.boundVocals != null)
				Conductor.boundVocals.play();

			Conductor.resyncTime();

			paused = false;
			canPause = true;
		}

		super.closeSubState();
	}

	// gotta check if this shit is actually lag free - move to character maybe?
	function trail(char:Character, note:Note):Void
	{
		var time:Float = 0;
		var anim:String = 'sing${Receptor.getArrowFromNum(note.noteData).toUpperCase()}';
		var daCopy:FlxSprite = char.clone();

		daCopy.active = false;
		daCopy.alpha = 0.5;

		daCopy.setPosition(char.x, char.y);
		daCopy.offset.set(char.animOffsets[anim][0], char.animOffsets[anim][1]);

		daCopy.animation.play(anim, true);

		if (note.isSustain && !note.isSustainEnd)
			time += 0.15;

		if (!note.isSustain)
			insert(members.indexOf(char) - 1, daCopy);

		if (!note.isSustain)
			runTween(daCopy, char.singDuration, time);
	}

	function runTween(daCopy:FlxSprite, singDuration:Float, delay:Float)
	{
		FlxTween.tween(daCopy, {alpha: 0}, (Conductor.stepCrochet * singDuration) / 1000, {
			startDelay: delay,
			onComplete: function(_)
			{
				daCopy.destroy();
				daCopy = null;
			}
		});
	}
}
