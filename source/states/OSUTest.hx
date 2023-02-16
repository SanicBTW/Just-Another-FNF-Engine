package states;

import base.Conductor;
import base.Controls;
import base.FadeTransition;
import base.MusicBeatState;
import base.SaveData;
import base.ScriptableState.ScriptableSubState;
import base.ScriptableState;
import base.SoundManager.AudioStream;
import base.osu.Beatmap;
import base.system.Scroll;
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

class OSUTest extends MusicBeatState
{
	public var beatmap:Beatmap;
	public var camHUD:FlxCamera;
	public var camHUD2:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	public var playerStrums:StrumLine;

	private var generatedMusic:Bool = false;

	private var hud:UI;

	public static var paused:Bool = false;
	public static var canPause:Bool = true;

	override public function new(bindBeatmap:Beatmap)
	{
		super();
		this.beatmap = bindBeatmap;
	}

	override function create()
	{
		Controls.setActions(NOTES);
		Ratings.call();

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		FlxCamera.defaultCameras = [camGame];

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther);

		playerStrums = new StrumLine((FlxG.width / 2), 4);
		playerStrums.onBotHit.add(playerBotHit);
		playerStrums.onMiss.add(playerMissPress);
		playerStrums.cameras = [camHUD];
		add(playerStrums);

		Conductor.songPosition = -5000;

		hud = new UI();
		add(hud);
		hud.cameras = [camHUD];

		generateSong();

		super.create();

		Paths.music("tea-time"); // precache the sound lol
		FadeTransition.nextCamera = camOther;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (generatedMusic)
		{
			while ((beatmap.Notes[0] != null) && (beatmap.Notes[0].strumTime - Conductor.songPosition) < 20000)
			{
				var unspawnNote:Note = beatmap.Notes[0];
				if (unspawnNote != null)
				{
					playerStrums.push(unspawnNote);
				}
				beatmap.Notes.splice(beatmap.Notes.indexOf(unspawnNote), 1);
			}

			playerStrums.holdGroup.forEachAlive(function(coolNote:Note)
			{
				if (coolNote.isSustain && coolNote.canBeHit && keys[coolNote.noteData])
				{
					playerHit(coolNote);
				}
			});
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
		possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

		if (possibleNoteList.length > 0)
		{
			var eligable:Bool = true;
			var firstNote:Bool = true;
			for (coolNote in possibleNoteList)
			{
				for (noteDouble in pressedNotes)
				{
					if (Math.abs(noteDouble.strumTime - coolNote.strumTime) < 10)
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

	private function playerHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			getReceptor(playerStrums, note.noteData).playAnim('confirm');

			if (!note.isSustain)
			{
				var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);
				var judgement:String = Ratings.judge(noteDiff);
				Ratings.updateAccuracy(Ratings.judgements[judgement][1]);
				if (note.children.length > 0)
					Ratings.notesHit++;
			}
			else
			{
				if (note.parent != null)
					Ratings.updateAccuracy(100, true, note.parent.children.length);
			}

			note.wasGoodHit = true;

			if (!note.isSustain)
				destroyNote(playerStrums, note);
		}
	}

	private function playerBotHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			getReceptor(playerStrums, note.noteData).playAnim('confirm');
			if (note.isSustain && note.isSustainEnd)
				getReceptor(playerStrums, note.noteData).playAnim('static');

			note.wasGoodHit = true;

			if (!note.isSustain)
				destroyNote(playerStrums, note);
		}
	}

	private function playerMissPress(note:Note)
	{
		var direction:Int = note.noteData;

		Ratings.misses++;
		Ratings.updateAccuracy(Ratings.judgements.get("miss")[1]);
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

	private function generateSong():Void
	{
		generatedMusic = true;

		Conductor.boundSong.onFinish.add(() ->
		{
			Conductor.boundSong.stop();
			ScriptableState.switchState(new MainState());
		});
		Conductor.boundSong.play();
		Conductor.resyncTime();
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (!paused)
		{
			if (Conductor.boundSong != null)
				Conductor.boundSong.stop();

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

			Conductor.resyncTime();

			paused = false;
			canPause = true;
		}

		super.closeSubState();
	}
}
