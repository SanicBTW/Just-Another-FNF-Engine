package states;

import base.MusicBeatState;
import funkin.notes.StrumLine;
import states.template.NotePlayfield;

class PlayState extends NotePlayfield<PlayState>
{
	override private function get_curStrumLine():StrumLine
		return strumLines.members[1];

	override private function setupStrums()
	{
		trace("shouldnt be any strums rn");
	}
}
