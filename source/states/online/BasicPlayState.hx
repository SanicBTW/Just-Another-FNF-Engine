package states.online;

import base.FadeTransition;
import base.MusicBeatState;
import base.ScriptableState;
import base.system.Conductor;
import base.system.Controls;
import base.system.DiscordPresence;
import base.system.SaveFile;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.Character;
import funkin.ChartLoader;
import funkin.CoolUtil;
import funkin.Stage;
import funkin.Timings;
import funkin.notes.Note;
import funkin.notes.Receptor;
import funkin.notes.StrumLine;
import funkin.ui.UI;
import openfl.filters.ShaderFilter;
import openfl.media.Sound;
import substates.PauseState;

using StringTools;

class BasicPlayState extends MusicBeatState
{
	// Instance to access non-static variables
	public static var instance:BasicPlayState;

	// Cameras
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	// Strum handling
	private var strumLines:FlxTypedGroup<StrumLine>;

	private var curStrumLine(get, null):StrumLine;

	@:noCompletion
	private function get_curStrumLine():StrumLine
		return strumLines.members[0];

	// Countdown
	public var startedCountdown:Bool = false;
	public var startingSong:Bool = false;

	private var startTimer:FlxTimer;

	// Input
	private static var receptorActionList:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	private var keys:Array<Bool> = [false, false, false, false];

	public var loadSong:Null<String> = "";

	override public function new(?loadSong:String)
	{
		super();
		this.loadSong = loadSong;
	}

	override function create()
	{
		if (FlxG.sound.music.playing)
			FlxG.sound.music.stop();

		Controls.setActions(NOTES);
		Timings.call();

		instance = this;

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

		generateSong();

		strumLines = new FlxTypedGroup<StrumLine>();
		strumLines.cameras = [camHUD];

		var separation:Float = FlxG.width / 4;

		var strum = new StrumLine((FlxG.width / 2), 4);
		strum.onMiss.add(noteMiss);
		strumLines.add(strum);

		add(strumLines);

		FlxG.camera.zoom = 1;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		Paths.music("tea-time"); // precache the sound lol
		DiscordPresence.changePresence('Playing ${SONG.song}');

		super.create();

		FadeTransition.nextCamera = camOther;

		setupIntro();
	}

	override function update(elapsed:Float)
	{
		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));

		while ((ChartLoader.unspawnedNoteList[0] != null) && (ChartLoader.unspawnedNoteList[0].strumTime - Conductor.songPosition) < 3500)
		{
			var unspawnNote:Note = ChartLoader.unspawnedNoteList[0];
			if (unspawnNote != null)
			{
				var strumLine:StrumLine = strumLines.members[unspawnNote.strumLine];
				if (strumLine != null)
					strumLine.push(unspawnNote);
			}
			ChartLoader.unspawnedNoteList.splice(ChartLoader.unspawnedNoteList.indexOf(unspawnNote), 1);
		}

		DiscordPresence.changePresence('Playing ${SONG.song}', null, null, true, Conductor.boundSong.length - Conductor.songPosition);

		// need a better way :sob:
		if (!updateTime)
		{
			Conductor.boundSong.stop();
			Conductor.boundVocals.stop();
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				if (startTimer.finished)
				{
					startingSong = false;
					updateTime = true;
					Conductor.resyncTime();
				}
			}
		}

		curStrumLine.allNotes.forEachAlive(function(coolNote:Note)
		{
			if ((coolNote.parent != null && coolNote.parent.wasGoodHit)
				&& coolNote.canBeHit
				&& !coolNote.tooLate
				&& !coolNote.wasGoodHit
				&& coolNote.isSustain
				&& keys[coolNote.noteData])
			{
				noteHit(coolNote);
			}
		});

		super.update(elapsed);

		if (Timings.health <= 0)
		{
			ScriptableState.switchState(new PlayTest(loadSong));
		}
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (curStrumLine.botPlay || !receptorActionList.contains(action))
			return;

		var data:Int = receptorActionList.indexOf(action);

		if (keys[data])
		{
			trace('already holding $action');
			return;
		}

		keys[data] = true;

		var lastTime:Float = Conductor.songPosition;
		Conductor.songPosition = Conductor.boundSong.time;

		var possibleNotes:Array<Note> = [];
		var directionList:Array<Int> = [];
		var dumbNotes:Array<Note> = [];

		curStrumLine.allNotes.forEachAlive(function(daNote:Note)
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
			curStrumLine.destroyNote(note);
		}

		possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

		if (possibleNotes.length > 0)
		{
			for (coolNote in possibleNotes)
			{
				if (keys[coolNote.noteData] && coolNote.canBeHit && !coolNote.tooLate)
					noteHit(coolNote);
			}
		}

		Conductor.songPosition = lastTime;

		if (getReceptor(curStrumLine, data).animation.curAnim.name != "confirm")
			getReceptor(curStrumLine, data).playAnim('pressed');
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);

		if (curStrumLine.botPlay || !receptorActionList.contains(action))
			return;

		var data:Int = receptorActionList.indexOf(action);
		keys[data] = false;

		getReceptor(curStrumLine, data).playAnim('static');
	}

	override public function beatHit()
	{
		super.beatHit();

		if (curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.05;
		}

		if (SONG.notes[Std.int(curStep / 16)] != null && SONG.notes[Std.int(curStep / 16)].changeBPM)
			Conductor.changeBPM(SONG.notes[Std.int(curStep / 16)].bpm);
	}

	private function setupIntro()
	{
		Conductor.songPosition = -(Conductor.crochet * 16);
		startingSong = true;
		startCountdown();
	}

	private function startCountdown()
	{
		Conductor.songPosition = -(Conductor.crochet * 5);
		startedCountdown = true;

		var introArray:Array<FlxGraphic> = [];
		var soundsArray:Array<Sound> = [];

		var introName:Array<String> = ['ready', 'set', 'go'];
		for (intro in introName)
			introArray.push(Paths.image('ui/$intro'));

		var soundNames:Array<String> = ['intro3', 'intro2', 'intro1', 'introGo'];
		for (sound in soundNames)
			soundsArray.push(Paths.sound(sound));

		var countdown:Int = -1;
		startTimer = new FlxTimer().start(Conductor.crochet / 1000, (tmr:FlxTimer) ->
		{
			if (countdown >= 0 && countdown < introArray.length)
			{
				var introSprite:FlxSprite = new FlxSprite().loadGraphic(introArray[countdown]);
				introSprite.scrollFactor.set();
				introSprite.updateHitbox();
				introSprite.screenCenter();
				introSprite.cameras = [camHUD];
				add(introSprite);

				FlxTween.tween(introSprite, {y: introSprite.y + 100, alpha: 0}, Conductor.crochet / 1000, {
					ease: FlxEase.cubeInOut,
					onComplete: (_) ->
					{
						introSprite.destroy();
					}
				});
			}
			countdown++;
			FlxG.sound.play(soundsArray[countdown], 0.6);
		}, 5);
	}

	private function generateSong():Void
	{
		SONG = ChartLoader.loadChart(this, (loadSong != null ? loadSong : ""), 2);
		Conductor.changeBPM(SONG.bpm);

		Conductor.boundSong.onComplete = function()
		{
			Conductor.boundSong.stop();
			Conductor.boundVocals.stop();
			ChartLoader.netChart = null;
			ChartLoader.netInst = null;
			ChartLoader.netVoices = null;
			ScriptableState.switchState(new RewriteMenu());
		};
		Conductor.boundSong.stop();
		Conductor.boundVocals.stop();
		updateTime = false;
	}

	private function noteHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			getReceptor(curStrumLine, note.noteData).playAnim('confirm');

			if (!note.isSustain)
			{
				note.ratingDiff = (-(note.strumTime - Conductor.songPosition));
				var rating:String = Timings.judge(note.ratingDiff);
				if (rating == "marvelous" || rating == "sick")
					playSplash(curStrumLine, note.noteData);
			}
			else
				Timings.judge(note.parent.ratingDiff, true);

			if (SONG.needsVoices)
				Conductor.boundVocals.volume = 1;

			if (!note.isSustain)
				curStrumLine.destroyNote(note);
		}
	}

	private function noteMiss(note:Note)
	{
		if (SONG.needsVoices)
			Conductor.boundVocals.volume = 0;

		Timings.judge(164);
	}

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];

	private function playSplash(strumLine:StrumLine, noteData:Int)
		strumLine.splashNotes.members[noteData].playAnim();
}
