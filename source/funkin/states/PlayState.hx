package funkin.states;

import Paths.Libraries;
import backend.Cache;
import backend.Controls;
import base.Conductor;
import base.MusicBeatState;
import base.ScriptableState;
import flixel.FlxCamera;
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
import transitions.FadeTransition;

class PlayState extends MusicBeatState
{
	// Cameras
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	// Strum handling
	private var strumLines:FlxTypedGroup<StrumLine>;

	public var playerStrums:StrumLine;
	public var opponentStrums:StrumLine;

	// Stage, UI and characters
	public static var stageBuild:Stage;

	var actionList:Array<Action> = [Action.NOTE_LEFT, Action.NOTE_DOWN, Action.NOTE_UP, Action.NOTE_RIGHT];

	private var conductorTracking:FlxText;

	override public function create()
	{
		ChartLoader.loadChart(SongSelection.songSelected.songName, SongSelection.songSelected.songDiff);
		Controls.targetActions = NOTES;

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

		strumLines = new FlxTypedGroup<StrumLine>();
		strumLines.cameras = [camHUD];

		var separation:Float = FlxG.width / 4;

		opponentStrums = new StrumLine((FlxG.width / 2) - separation, FlxG.height / 6);
		opponentStrums.botPlay = true;
		opponentStrums.onBotHit.add(botHit);
		strumLines.add(opponentStrums);

		playerStrums = new StrumLine((FlxG.width / 2) + separation, FlxG.height / 6);
		playerStrums.onMiss.add(noteMiss);
		strumLines.add(playerStrums);

		add(strumLines);

		stageBuild = new Stage("stage");
		add(stageBuild);

		conductorTracking = new FlxText(15, 15, 0, 'Steps: ?\n Beats: ?\nBPM: ${Conductor.bpm}', 24);
		conductorTracking.setFormat(Paths.font('vcr.ttf'), 24);
		add(conductorTracking);

		FlxG.camera.zoom = (stageBuild != null) ? stageBuild.defaultCamZoom : 1;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		super.create();

		FadeTransition.nextCamera = camOther;

		Conductor.boundInst.onComplete = () ->
		{
			ScriptableState.switchState(new SongSelection());
		}
	}

	override function update(elapsed:Float)
	{
		while ((ChartLoader.noteQueue[0] != null) && (ChartLoader.noteQueue[0].strumTime - Conductor.songPosition) < 3500)
		{
			var nextNote:Note = ChartLoader.noteQueue[0];
			if (nextNote != null)
			{
				var strumLine:StrumLine = strumLines.members[nextNote.strumLine];
				if (strumLine != null)
					strumLine.push(nextNote);
				else
				{
					// If we cant push to the targeted strum line, then we push to the current one and mark the note as must press so it  can be pressed lol
					nextNote.mustPress = true;
					playerStrums.push(nextNote);
				}
			}
			ChartLoader.noteQueue.splice(ChartLoader.noteQueue.indexOf(nextNote), 1);
		}

		conductorTracking.text = 'Steps: ${curStep}\nBeats: ${curBeat}\nBPM: ${Conductor.bpm}';
		super.update(elapsed);

		holdNotes(elapsed);
	}

	override private function onActionPressed(action:String)
	{
		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case "reset":
				return;

			case "back":
				Conductor.boundInst.stop();
				Conductor.boundVocals.stop();
				ScriptableState.switchState(new SongSelection());

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

	private function holdNotes(elapsed:Float)
	{
		if (playerStrums == null)
			return;

		var holdArray:Array<Bool> = parseKeys();

		if (!playerStrums.botPlay)
		{
			playerStrums.allNotes.forEachAlive(function(coolNote:Note)
			{
				/*
					var isHeld:Bool = holdArray[coolNote.noteData];
					if (coolNote.canBeHit && coolNote.parent != null && coolNote.holdingTime < coolNote.parent.sustainLength)
					{
						if (!coolNote.tooLate && coolNote.parent.wasGoodHit)
						{
							var receptor:Receptor = playerStrums.receptors.members[coolNote.noteData];
							if (isHeld && receptor.animation.curAnim.name != "confirm")
								receptor.playAnim('confirm');

							coolNote.holdingTime = Conductor.songPosition - coolNote.strumTime;

							var regrabTime:Float = 0.2;

							if (isHeld)
								coolNote.tripTimer = 1;
							else
								coolNote.tripTimer -= elapsed / regrabTime;

							if (coolNote.tripTimer <= 0)
							{
								coolNote.tripTimer = 0;
								trace('Tripped on hold');
								coolNote.tooLate = true;
								coolNote.wasGoodHit = false;
								for (tail in coolNote.tail)
									if (!tail.wasGoodHit)
										tail.tooLate = true;
							}
							else
							{
								for (tail in coolNote.unhitTail)
								{
									if ((tail.strumTime - 25) <= Conductor.songPosition && !tail.wasGoodHit && !tail.tooLate)
										noteHit(tail);
								}

								if (coolNote.holdingTime >= coolNote.sustainLength)
								{
									trace("finished sustain");
									coolNote.holdingTime = coolNote.sustainLength;
								}
							}
						}
				}*/

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
			var diff = note.strumTime - Conductor.songPosition;
			// trace(diff);

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
