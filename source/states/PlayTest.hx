package states;

import base.Conductor;
import base.MusicBeatState;
import base.Song;
import base.SoundManager.AudioStream;
import flixel.FlxG;
import funkin.notes.Note;
import funkin.notes.StrumLine;

class PlayTest extends MusicBeatState
{
	public static var SONG:SwagSong;

	private var boyfriendStrums:StrumLine;

	override function create()
	{
		Paths.clearStoredMemory();

		SONG = Song.loadFromJSON("bopeebo");

		var shitinst = new AudioStream();
		var shitvoices = new AudioStream();
		shitinst.source = Paths.inst("bopeebo");
		shitvoices.source = Paths.voices("bopeebo");
		Conductor.bindSong(this, shitinst, SONG.bpm, shitvoices);

		super.create();

		Conductor.boundSong.play();
		Conductor.boundVocals.play();
		Conductor.resyncTime();

		Paths.clearUnusedMemory();

		boyfriendStrums = new StrumLine(FlxG.width / 2, 4);
		add(boyfriendStrums);
	}
}
