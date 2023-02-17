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
		playerStrums.cameras = [camHUD];
		add(playerStrums);

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
			for (note in beatmap.Notes)
			{
				var baseX:Float = playerStrums.receptors.members[Math.floor(note.noteData)].x;
				var baseY:Float = playerStrums.receptors.members[Math.floor(note.noteData)].y;
				note.x = baseX + note.offsetX;
				note.y = baseY + note.offsetY + (-(Scroll.POSITION - note.strumTime)) * (Conductor.bpm / 100);
				note.visible = true;
				note.active = true;

				if (note.isSustain && note.canBeHit && keys[note.noteData])
					playerHit(note);
			}
		}
	}

	// kade way
	private static var receptorActionList:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	private var keys:Array<Bool> = [false, false, false, false];

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

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

		for (daNote in beatmap.Notes)
		{
			if ((daNote.noteData == data) && !daNote.isSustain && daNote.canBeHit && !daNote.tooLate && daNote.alive)
				possibleNoteList.push(daNote);
		}
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

			note.wasGoodHit = true;

			if (!note.isSustain)
				destroyNote(playerStrums, note);
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

	private function generateSong():Void
	{
		generatedMusic = true;

		Conductor.boundSong.onFinish.add(() ->
		{
			Conductor.boundSong.stop();
			ScriptableState.switchState(new MainState());
		});
		Conductor.boundSong.play();
		Scroll.init();
		Conductor.resyncTime();
	}
}
