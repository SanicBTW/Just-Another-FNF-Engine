package funkin.states;

import Paths.Libraries;
import backend.Cache;
import backend.Controls;
import base.Conductor;
import base.InteractionState;
import base.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
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

class PlayState extends MusicBeatState
{
	private var strumLines:FlxTypedGroup<StrumLine>;

	public var playerStrums:StrumLine;
	public var opponentStrums:StrumLine;

	var actionList:Array<Action> = [Action.NOTE_LEFT, Action.NOTE_DOWN, Action.NOTE_UP, Action.NOTE_RIGHT];

	private var conductorTracking:FlxText;

	override public function create()
	{
		ChartLoader.loadChart(SongSelection.songSelected.songName, SongSelection.songSelected.songDiff);
		Controls.targetActions = NOTES;

		strumLines = new FlxTypedGroup<StrumLine>();

		var separation:Float = FlxG.width / 4;

		opponentStrums = new StrumLine((FlxG.width / 2) - separation, 4);
		opponentStrums.botPlay = true;
		opponentStrums.visible = false;
		opponentStrums.onBotHit.add(botHit);
		strumLines.add(opponentStrums);

		playerStrums = new StrumLine((FlxG.width / 2), 4);
		playerStrums.onMiss.add(noteMiss);
		strumLines.add(playerStrums);

		add(strumLines);

		conductorTracking = new FlxText(15, 15, 0, 'Steps: ?\n Beats: ?\nBPM: ${Conductor.bpm}', 24);
		conductorTracking.setFormat(Paths.font('vcr.ttf'), 24);
		add(conductorTracking);

		super.create();

		Conductor.boundInst.onComplete = () ->
		{
			InteractionState.switchState(new SongSelection());
		}
	}

	override function update(elapsed:Float)
	{
		while ((ChartLoader.unspawnedNotes[0] != null) && (ChartLoader.unspawnedNotes[0].strumTime - Conductor.songPosition) < 3500)
		{
			var unspawnNote:Note = ChartLoader.unspawnedNotes[0];
			if (unspawnNote != null)
			{
				var strumLine:StrumLine = strumLines.members[unspawnNote.strumLine];
				if (strumLine != null)
					strumLine.push(unspawnNote);
				else
				{
					// If we cant push to the targeted strum line, then we push to the current one and mark the note as must press so it  can be pressed lol
					unspawnNote.mustPress = true;
					playerStrums.push(unspawnNote);
				}
			}
			ChartLoader.unspawnedNotes.splice(ChartLoader.unspawnedNotes.indexOf(unspawnNote), 1);
		}

		conductorTracking.text = 'Steps: ${curStep}\nBeats: ${curBeat}\nBPM: ${Conductor.bpm}';
		super.update(elapsed);

		holdNotes();
	}

	override private function onActionPressed(action:String)
	{
		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case "back" | "reset":
				return;

			case "confirm":
				Conductor.boundInst.play();

			default:
				for (receptor in playerStrums.receptors)
				{
					if (action == receptor.action)
					{
						var lastTime:Float = Conductor.songPosition;
						Conductor.songPosition = Conductor.boundInst.time;

						var possibleNoteList:Array<Note> = [];
						var pressedNotes:Array<Note> = [];

						playerStrums.notesGroup.forEachAlive(function(daNote:Note)
						{
							if ((daNote.noteData == receptor.noteData)
								&& !daNote.isSustain
								&& daNote.canBeHit
								&& !daNote.wasGoodHit
								&& !daNote.tooLate)
								possibleNoteList.push(daNote);
						});

						possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						if (possibleNoteList.length > 0)
						{
							var eligable = true;
							var firstNote = true;
							// loop through the possible notes
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
									noteHit(coolNote);
									pressedNotes.push(coolNote);
								}
								// end of this little check
							}
							//
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

	private function holdNotes()
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

	private function noteHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			getReceptor(playerStrums, note.noteData).playAnim('confirm');

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
	}

	private function botHit(note:Note)
	{
		var curStrums:StrumLine = (note.mustPress ? playerStrums : opponentStrums);
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;

			if (SONG.needsVoices)
				Conductor.boundVocals.volume = 1;

			var time:Float = 0.15;
			if (note.isSustain)
				time += 0.15;

			getReceptor(curStrums, note.noteData).playAnim('confirm', true);
			getReceptor(curStrums, note.noteData).holdTimer = time;

			if (!note.isSustain)
				curStrums.destroyNote(note);
		}
	}

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];
}
