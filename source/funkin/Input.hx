package funkin;

import base.system.Conductor.*;
import funkin.notes.*;

class Input
{
	// Input, Kade Engine way
	private static var receptorActionList:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	public static var keys:Array<Bool> = [false, false, false, false];

	public static function handlePress(action:String, strumLine:StrumLine, character:Character):Note
	{
		if (strumLine.botPlay || !receptorActionList.contains(action))
			return null;

		var data:Int = receptorActionList.indexOf(action);
		keys[data] = true;

		var lastTime:Float = songPosition;
		songPosition = boundSong.time;

		var possibleNotes:Array<Note> = [];
		var directionList:Array<Int> = [];
		var dumbNotes:Array<Note> = [];

		strumLine.allNotes.forEachAlive((daNote:Note) ->
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
			strumLine.destroyNote(note);
		}

		possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

		if (possibleNotes.length > 0)
		{
			for (coolNote in possibleNotes)
			{
				if (keys[coolNote.noteData] && coolNote.canBeHit && !coolNote.tooLate)
				{
					return coolNote;
				}
			}
		}

		songPosition = lastTime;

		if (strumLine.receptors.members[data].animation.curAnim.name != "confirm")
			strumLine.receptors.members[data].playAnim('pressed');

		return null;
	}

	public static function handleRelease(action:String, strumLine:StrumLine)
	{
		if (strumLine.botPlay || !receptorActionList.contains(action))
			return;

		var data:Int = receptorActionList.indexOf(action);
		keys[data] = false;

		strumLine.receptors.members[data].playAnim('static');
	}
}
