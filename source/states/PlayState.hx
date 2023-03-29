package states;

import base.MusicBeatState;
import funkin.ChartLoader;
import funkin.notes.StrumLine;
import states.template.NotePlayfield;

class PlayState extends NotePlayfield<PlayState>
{
	public var loadSong:Null<String> = "";

	override public function create()
	{
		super.create();
	}

	override public function new(?loadSong:String)
	{
		super();
		this.loadSong = loadSong;
	}

	override private function generateSong()
	{
		SONG = ChartLoader.loadChart(this, loadSong, 2);

		super.generateSong();
	}
}
