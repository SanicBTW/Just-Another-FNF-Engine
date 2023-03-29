package states.template;

import base.FadeTransition;
import base.MusicBeatState;
import base.ScriptableState;
import base.system.Conductor;
import base.system.Controls;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.ChartLoader;
import funkin.CoolUtil;
import funkin.Timings;
import funkin.notes.Note;
import funkin.notes.Receptor;
import funkin.notes.StrumLine;
import openfl.media.Sound;

// Handles strums, input, section lines and countdown
// Should be extended to avoid filling play state with the play handling
// Each function can be overriden to extend its functionality
// Made so I could sync changes with all playstates without having to do so manually
class NotePlayfield<T> extends MusicBeatState
{
	// Instance to access non-static variables
	public static var instance:NotePlayfield<T>;

	// Cameras
	private var camGame:FlxCamera;
	private var camHUD:FlxCamera;
	private var camNotes:FlxCamera;
	private var camOther:FlxCamera;

	// Strum handling
	private var strumLines:FlxTypedGroup<StrumLine>;

	// Can be overriden
	public var playerStrums(get, null):StrumLine;

	@:noCompletion
	private function get_playerStrums():StrumLine
		return strumLines.members[1];

	public var opponentStrums(get, null):StrumLine;

	@:noCompletion
	private function get_opponentStrums():StrumLine
		return strumLines.members[0];

	/*
		// Can be overriden to support 2 or more strum lines
		public var curStrumLine(get, null):StrumLine;
		@:noCompletion
		private function get_curStrumLine():StrumLine
			return strumLines.members[1]; */
	// Countdown
	public var startedCountdown:Bool = false;
	public var startingSong:Bool = false;

	// Camera zooming
	public var cameraZoom:Float = 1;

	// Input, Kade Engine way
	private static var receptorActionList:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	private var keys:Array<Bool> = [false, false, false, false];

	// Here is where the magic happens
	override function create()
	{
		Controls.setActions(NOTES);
		Timings.call();

		instance = this;

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		camHUD = new FlxCamera();
		FlxG.cameras.add(camHUD, false);

		camNotes = new FlxCamera();
		FlxG.cameras.add(camNotes, false);

		camOther = new FlxCamera();
		FlxG.cameras.add(camOther, false);

		generateSong();

		strumLines = new FlxTypedGroup<StrumLine>();
		strumLines.camera = camNotes;
		add(strumLines);

		setupStrums();

		// should handle camera stuff in each playstate
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		Paths.music("tea-time");
		FadeTransition.nextCamera = camOther;

		setupIntro();

		super.create();
	}

	// Can be overriden to add more strums
	private function setupStrums()
	{
		var separation:Float = FlxG.width / 4;

		// dad strums
		var strumLine:StrumLine = new StrumLine((FlxG.width / 2) - separation, 4);
		strumLine.botPlay = true;
		strumLine.onBotHit.add((_) -> {});
		strumLines.add(strumLine);

		var strumLine:StrumLine = new StrumLine((FlxG.width / 2) + separation, 4);
		strumLine.onBotHit.add((_) -> {});
		strumLine.onMiss.add((_) -> {});
		strumLines.add(strumLine);
	}

	// Override these 2 on play state to set UI alpha and use tweens
	private function setupIntro()
	{
		Conductor.songPosition = -(Conductor.crochet * 16);
		startingSong = true;
		startCountdown();
	}

	// From https://github.com/SanicBTW/Forever-Engine-Archive/blob/rewrite/source/states/PlayState.hx#L501
	private function startCountdown()
	{
		Conductor.songPosition = -(Conductor.crochet * 5);
		startedCountdown = true;

		for (strumLine in strumLines)
		{
			for (i in 0...strumLine.receptors.length)
			{
				var receptor:Receptor = strumLine.receptors.members[i];
				FlxTween.tween(strumLine.receptors.members[i], {y: receptor.initialY, alpha: receptor.setAlpha}, (Conductor.crochet * 4) / 1000,
					{ease: FlxEase.circOut, startDelay: (Conductor.crochet / 1000) + ((Conductor.stepCrochet / 1000) * i)});
			}
		}

		var introArray:Array<FlxGraphic> = [];
		var soundsArray:Array<Sound> = [];

		var introName:Array<String> = ['ready', 'set', 'go'];
		for (intro in introName)
			introArray.push(Paths.image('ui/$intro'));

		var soundNames:Array<String> = ['intro3', 'intro2', 'intro1', 'introGo'];
		for (sound in soundNames)
			soundsArray.push(Paths.sound(sound));

		var countdown:Int = -1;
		// TODO: clean after finishing
		var startTimer:FlxTimer = new FlxTimer().start(Conductor.crochet / 1000, (tmr:FlxTimer) ->
		{
			if (countdown >= 0 && countdown < introArray.length)
			{
				var introSprite:FlxSprite = new FlxSprite().loadGraphic(introArray[countdown]);
				introSprite.scrollFactor.set();
				introSprite.updateHitbox();
				introSprite.screenCenter();
				add(introSprite);

				FlxTween.tween(introSprite, {y: introSprite.y += 100, alpha: 0}, Conductor.crochet / 1000, {
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

	private function generateSong()
	{
		SONG = ChartLoader.loadChart(this, "", 2);

		Conductor.boundSong.onComplete = () ->
		{
			Conductor.boundSong.stop();
			Conductor.boundVocals.stop();
			ChartLoader.netChart = null;
			ChartLoader.netInst = null;
			ChartLoader.netVoices = null;
			ScriptableState.switchState(new AlphabetMenu());
		}
	}

	override public function update(elapsed:Float)
	{
		FlxG.camera.zoom = FlxMath.lerp(cameraZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));

		super.update(elapsed);

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += elapsed * 1000;
				if (Conductor.songPosition >= 0)
				{
					startingSong = false;
					Conductor.resyncTime();
				}
			}
		}

		while ((ChartLoader.unspawnedNoteList[0] != null) && (ChartLoader.unspawnedNoteList[0].strumTime - Conductor.songPosition) < 3500)
		{
			var unspawnNote:Note = ChartLoader.unspawnedNoteList[0];
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
			ChartLoader.unspawnedNoteList.splice(ChartLoader.unspawnedNoteList.indexOf(unspawnNote), 1);
		}

		// look into this
		playerStrums.allNotes.forEachAlive((coolNote:Note) ->
		{
			if ((coolNote.parent != null && coolNote.parent.wasGoodHit)
				&& coolNote.canBeHit
				&& !coolNote.tooLate
				&& !coolNote.wasGoodHit
				&& coolNote.isSustain
				&& keys[coolNote.noteData]) {}
		});
	}

	// might add smashing prevention?
	// rewrite soon or smth
	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (playerStrums.botPlay || !receptorActionList.contains(action))
			return;

		var data:Int = receptorActionList.indexOf(action);
		keys[data] = true;

		var lastTime:Float = Conductor.songPosition;
		Conductor.songPosition = Conductor.boundSong.time;

		var possibleNotes:Array<Note> = [];
		var directionList:Array<Int> = [];
		var dumbNotes:Array<Note> = [];

		playerStrums.allNotes.forEachAlive((daNote:Note) ->
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
			playerStrums.destroyNote(note);
		}

		possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

		if (possibleNotes.length > 0)
		{
			for (coolNote in possibleNotes)
			{
				if (keys[coolNote.noteData] && coolNote.canBeHit && !coolNote.tooLate) {}
			}
		}

		Conductor.songPosition = lastTime;

		if (getReceptor(playerStrums, data).animation.curAnim.name != "confirm")
			getReceptor(playerStrums, data).playAnim('pressed');
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);

		if (playerStrums.botPlay || !receptorActionList.contains(action))
			return;

		var data:Int = receptorActionList.indexOf(action);
		keys[data] = false;

		getReceptor(playerStrums, data).playAnim('static');
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

	private function noteHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			getReceptor(playerStrums, note.noteData).playAnim('confirm');

			if (!note.isSustain)
			{
				note.ratingDiff = (-(note.strumTime - Conductor.songPosition));
				var rating:String = Timings.judge(note.ratingDiff);
				if (rating == "marvelous" || rating == "sick")
					playSplash(playerStrums, note.noteData);
			}
			else
				Timings.judge(note.parent.ratingDiff, true);

			if (SONG.needsVoices)
				Conductor.boundVocals.volume = 1;

			if (!note.isSustain)
				playerStrums.destroyNote(note);
		}
	}

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];

	private function playSplash(strumLine:StrumLine, noteData:Int)
		strumLine.splashNotes.members[noteData].playAnim();
}
