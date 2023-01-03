package states;

import base.Conductor;
import base.Controls;
import base.MusicBeatState;
import base.Song;
import base.SoundManager.AudioStream;
import flixel.FlxG;
import flixel.math.FlxRect;
import funkin.ChartLoader;
import funkin.notes.Note;
import funkin.notes.StrumLine;

class PlayTest extends MusicBeatState
{
	public static var SONG:SwagSong;

	private var boyfriendStrums:StrumLine;

	@:isVar private var curStep(get, null):Int;

	private function get_curStep():Int
		return Conductor.stepPosition;

	@:isVar private var unspawnNotes(get, null):Array<Note>;

	private function get_unspawnNotes():Array<Note>
		return ChartLoader.unspawnedNotesList;

	override function create()
	{
		Paths.clearStoredMemory();

		Controls.setActions(NOTES);

		SONG = ChartLoader.loadChart(this, "bopeebo", 2);

		boyfriendStrums = new StrumLine(FlxG.width / 2, 4);
		add(boyfriendStrums);

		super.create();

		Conductor.boundSong.play();
		Conductor.boundVocals.play();
		Conductor.resyncTime();

		Paths.clearUnusedMemory();
	}

	public var closestNotes:Array<Note> = [];

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Conductor.boundSong.playing)
		{
			if (unspawnNotes.length > 0)
			{
				while (unspawnNotes[0] != null
					&& (unspawnNotes[0].stepTime + (-(16 * Conductor.stepCrochet) / Conductor.stepCrochet)) <= curStep)
				{
					var swagNote:Note = unspawnNotes[0];
					boyfriendStrums.add(swagNote);
					unspawnNotes.splice(unspawnNotes.indexOf(swagNote), 1);
				}
			}

			if (SONG.notes[Std.int(curStep / 16)] != null)
			{
				closestNotes = [];

				boyfriendStrums.allNotes.forEachAlive(function(swagNote:Note)
				{
					if (swagNote.canBeHit && swagNote.mustPress && !swagNote.tooLate && !swagNote.wasGoodHit)
						closestNotes.push(swagNote);
				});

				closestNotes.sort((a, b) -> Std.int(a.stepTime - b.stepTime));
			}

			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			boyfriendStrums.allNotes.forEachAlive(function(strumNote:Note)
			{
				if (strumNote.tooLate)
				{
					strumNote.active = false;
					strumNote.visible = false;
				}
				else
				{
					strumNote.visible = true;
					strumNote.active = true;
				}

				var baseX:Float = boyfriendStrums.receptors.members[Math.floor(strumNote.noteData)].x;
				var baseY:Float = boyfriendStrums.receptors.members[Math.floor(strumNote.noteData)].y;

				strumNote.x = baseX + strumNote.offsetX;
				strumNote.y = baseY
					+ strumNote.offsetY
					+ (-(Conductor.songPosition - (strumNote.stepTime * Conductor.stepCrochet)) * (0.45 * strumNote.noteSpeed));

				var center:Float = baseY + (Note.swagWidth / 2);
				if (strumNote.isSustain)
				{
					strumNote.y -= (Note.swagWidth / 2);

					if (strumNote.y + strumNote.offsetY * strumNote.scale.y <= center
						&& (strumNote.wasGoodHit || (strumNote.prevNote != null && strumNote.prevNote.wasGoodHit)))
					{
						var swagRect:FlxRect = new FlxRect(0, 0, strumNote.width / strumNote.scale.x, strumNote.height / strumNote.scale.y);
						swagRect.y = (center - strumNote.y) / strumNote.scale.y;
						swagRect.height -= swagRect.y;
						strumNote.clipRect = swagRect;
					}
				}
			});
		}
	}
}
