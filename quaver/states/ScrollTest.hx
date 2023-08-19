package states;

import backend.*;
import backend.Conductor.BPMChange;
import backend.Controls.ActionType;
import engine.SBar;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxTiledSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxSort;
import funkin.Song;
import network.MultiCallback;
import network.pocketbase.Collection;
import network.pocketbase.PBRequest;
import network.pocketbase.Record.FunkinRecord;
import network.pocketbase.User;
import openfl.display.BlendMode;
import openfl.media.Sound;
import quaver.Qua;
import quaver.notes.Note;
import quaver.notes.Receptor;
import quaver.notes.StrumLine;

using Lambda;
using backend.Extensions;

class ScrollTest extends FlxState
{
	public static var Controls:Controls = new Controls();
	public static var Paths:IsolatedPaths = new IsolatedPaths('quaver');
	public static var LocalPaths:IsolatedPaths = new IsolatedPaths(haxe.io.Path.join([lime.system.System.documentsDirectory, "just_another_fnf_engine", "quaver"]));
	public static var Conductor:Conductor;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var camBG:FlxCamera;
	var camOther:FlxCamera;

	var strums:FlxTypedGroup<StrumLine>;
	var playerStrums:StrumLine;
	var opponentStrums:StrumLine;
	// Dedicated cam for the strums so scrolling actually works and shit i hate my life
	var strumCam:FlxCamera;

	// aye i will change the dumb password wen i finish them online servers and support shit
	var qua:Qua = null;
	var swagShit:SwagSong = null;

	var shitNotes:Array<Note> = [];
	var voices:FlxSound = new FlxSound();

	var timeBar:SBar;

	override public function create()
	{
		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		camGame.bgColor.alpha = 0;
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		camBG = new FlxCamera();
		camBG.bgColor.alpha = 0;
		FlxG.cameras.add(camBG, false);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		strumCam = new FlxCamera();
		strumCam.bgColor.alpha = 0;
		FlxG.cameras.add(strumCam, false);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther, false);

		strums = new FlxTypedGroup<StrumLine>();
		strums.cameras = [strumCam];
		add(strums);

		timeBar = new SBar(FlxG.width - 100, 0, 15, FlxG.height - 150, FlxColor.WHITE, FlxColor.GRAY);
		timeBar.cameras = [camHUD];
		timeBar.angle = 360;
		timeBar.fillAxis = VERTICAL;
		timeBar.screenCenter(Y);
		add(timeBar);

		// Automatic update haha
		// Gotta create it on create (haha i want to kms) because of some issue with them signals and events lol
		Conductor = new Conductor();
		add(Conductor);

		backend.Controls.onActionPressed.add(onActionPressed);
		backend.Controls.onActionReleased.add(onActionReleased);

		generateChart();

		FlxG.camera.zoom = 1;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		super.create();
	}

	override function update(elapsed:Float)
	{
		var lerpVal:Float = FlxMath.bound(1 - (elapsed * 3.125), 0, 1);

		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, lerpVal);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, lerpVal);
		strumCam.zoom = FlxMath.lerp(1, strumCam.zoom, lerpVal);

		if (FlxG.sound.music != null)
			timeBar.value = FlxMath.lerp(Conductor.time / FlxG.sound.music.length, timeBar.value, lerpVal);

		noteSpawn();

		holdNotes(elapsed);

		super.update(elapsed);

		if (swagShit != null)
		{
			if (FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				if (Math.abs(FlxG.sound.music.time - Conductor.time) > Conductor.resyncThreshold
					|| (swagShit.needsVoices && Math.abs(voices.time - Conductor.time) > Conductor.resyncThreshold))
				{
					trace('Resyncing song time ${FlxG.sound.music.time}, ${Conductor.time}');
					if (swagShit.needsVoices)
						voices.pause();

					Conductor.time = FlxG.sound.music.time;

					if (swagShit.needsVoices)
					{
						voices.time = Conductor.time;
						voices.play();
					}

					trace('New song time ${FlxG.sound.music.time}, ${Conductor.time}');
				}

				Conductor.time += elapsed * 1000;
			}
		}

		if (strums.length > 0)
		{
			if (FlxG.keys.pressed.ALT)
			{
				for (strum in strums)
				{
					if (FlxG.mouse.justPressedMiddle)
						strum.scrollSpeed = 1;

					strum.scrollSpeed += (FlxG.mouse.wheel * 0.1);
				}
			}

			if (qua != null)
			{
				while (qua.SliderVelocities.length > 0)
				{
					var veloc:SliderVelocity = qua.SliderVelocities.unsafeGet(0);
					if (Conductor.time < veloc.StartTime)
						break;

					for (strum in strums)
					{
						strum.scrollSpeed = 1 * veloc.Multiplier;
					}

					qua.SliderVelocities.shift();
				}
			}
		}
	}

	override function destroy()
	{
		backend.Controls.onActionPressed.remove(onActionPressed);
		backend.Controls.onActionReleased.remove(onActionReleased);

		super.destroy();
	}

	function generateBackground()
	{
		// dark background
		var funkyBack:FlxSprite = new FlxSprite().loadGraphic(Paths.image('chart/bg'));
		funkyBack.setGraphicSize(Std.int(FlxG.width));
		funkyBack.cameras = [camBG];
		funkyBack.scrollFactor.set();
		funkyBack.blend = BlendMode.DIFFERENCE;
		funkyBack.screenCenter();
		funkyBack.alpha = 0.07;
		add(funkyBack);

		opponentStrums = new StrumLine((FlxG.width / 2) - FlxG.width / 4);
		opponentStrums.cameras = strums.cameras;
		opponentStrums.botPlay = true;
		strums.add(opponentStrums);

		playerStrums = new StrumLine((FlxG.width / 2) + FlxG.width / 4);
		playerStrums.cameras = strums.cameras;
		strums.add(playerStrums);

		if (swagShit != null)
		{
			for (strum in strums)
			{
				strum.scrollSpeed = 0.45 * swagShit.speed;
			}
		}
	}

	function generateChart()
	{
		/*
			qua = new Qua(Cache.getText(Paths.getPath('107408/107408.qua')));
			FlxG.sound.playMusic(Cache.getSound(#if FS_ACCESS LocalPaths.getPath('${qua.MapId}/${qua.AudioFile}') #else Paths.getPath('${qua.MapId}/${qua.AudioFile}') #end),
				1,
				false);
			FlxG.sound.music.stop();
			Conductor.bpm = qua.TimingPoints[0].Bpm;

			for (hitObject in qua.HitObjects)
			{
				var startTime:Float = (hitObject.StartTime / Conductor.stepCrochet);
				var noteData:Int = hitObject.Lane - 1;
				var endTime:Float = 0;

				if (hitObject.EndTime > 0)
					endTime = (hitObject.EndTime / Conductor.stepCrochet);

				var oldNote:Note = null;
				if (shitNotes.length > 0)
					oldNote = shitNotes[shitNotes.length - 1];

				var newNote:Note = new Note(startTime, noteData, oldNote);
				newNote.strumLine = 1;
				newNote.isSustain = (endTime > 0);
				newNote.sustainLength = (endTime > 0) ? Math.floor((endTime - startTime)) + 1 : 0;
				shitNotes.push(newNote);
			}
			generateBackground(); */

		var endChart:String = '';
		var endInst:Sound = new Sound();
		var endVoices:Null<Sound> = null;

		var netCb:MultiCallback = new MultiCallback(() ->
		{
			swagShit = Song.createFromRaw(endChart);

			if (endVoices == null)
				swagShit.needsVoices = false;

			Conductor.changeBPM(swagShit.bpm);

			FlxG.sound.music = new FlxSound();
			FlxG.sound.music.loadEmbedded(endInst);

			FlxG.sound.music.onComplete = function()
			{
				FlxG.resetState();
			}

			voices.loadEmbedded(endVoices);
			FlxG.sound.list.add(voices);

			generateBackground();
			Conductor.active = false;
		});

		PBRequest.getRecords('funkin', (funky:Collection<FunkinRecord>) ->
		{
			funky.items.shuffle();

			var selected:FunkinRecord = funky.items.randomElement();

			var chartCb:() -> Void = netCb.add("chart:" + selected.id);
			var instCb:() -> Void = netCb.add("inst:" + selected.id);
			var voicesCb:() -> Void = netCb.add("voices:" + selected.id);

			PBRequest.getFile(selected, 'chart', (chart:String) ->
			{
				endChart = chart;
				trace('finished loading chart');
				chartCb();

				PBRequest.getFile(selected, 'inst', (inst:Sound) ->
				{
					endInst = inst;
					trace('finished loading inst');
					instCb();

					if (selected.voices != '')
					{
						PBRequest.getFile(selected, 'voices', (voices:Sound) ->
						{
							endVoices = voices;
							trace('finished loading voices');
							voicesCb();
						}, SOUND);
					}
					else
						voicesCb();
				}, SOUND);
			}, RAW_STRING);
		});

		Conductor.onStepHit.add((curStep) ->
		{
			if (swagShit != null)
				if (swagShit.notes[Std.int(curStep / 16)] != null && swagShit.notes[Std.int(curStep / 16)].changeBPM)
				{
					Conductor.changeBPM(swagShit.notes[Std.int(curStep / 16)].bpm);
				}
		});

		Conductor.onBeatHit.add((curBeat) ->
		{
			if (curBeat % 4 == 0)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
				strumCam.zoom += 0.015;
			}
		});
	}

	private function noteSpawn()
	{
		if (FlxG.sound.music == null || swagShit == null)
			return;

		var curSection:funkin.Song.SwagSection = swagShit.notes[Std.int(Conductor.roundStep / 16)];
		if (curSection == null)
			return;

		var curNote:Dynamic = curSection.sectionNotes[0];
		if (curNote == null)
		{
			curSection = swagShit.notes[Std.int(Conductor.roundStep / 16) + 1];
			if (curSection == null)
				return;

			curNote = curSection.sectionNotes[0];
			if (curNote == null)
				return;
		}

		if (curNote[1] > -1)
		{
			var stepTime:Float = (curNote[0] / Conductor.stepCrochet);
			var sustainTime:Float = 0;
			var noteData:Int = Std.int(curNote[1] % 4);
			var hitNote:Bool = (curNote[1] > 3) ? !curSection.mustHitSection : curSection.mustHitSection;

			if (curNote[2] > 0)
				sustainTime = (curNote[2] / Conductor.stepCrochet);

			var strumLine:Int = (hitNote ? 1 : 0);

			var oldNote:Note = null;
			if (shitNotes.length > 0)
				oldNote = shitNotes[shitNotes.length - 1];

			var nextNote:Note = new Note(stepTime, noteData, oldNote, false);
			nextNote.mustPress = hitNote;
			nextNote.strumLine = strumLine;
			nextNote.isSustain = (sustainTime > 0);
			nextNote.sustainLength = (sustainTime > 0) ? Math.floor(sustainTime) + 1 : 0;
			shitNotes.push(nextNote);

			curSection.sectionNotes.splice(curSection.sectionNotes.indexOf(curNote), 1);
		}

		while ((shitNotes[0] != null) && (shitNotes[0].strumTime - Conductor.time) <= strumCam.scroll.y + strumCam.height)
		{
			var nextNote:Note = shitNotes[0];
			if (nextNote != null)
			{
				var strumLine:StrumLine = strums.members[nextNote.strumLine];
				if (strumLine != null)
					strumLine.pushNote(nextNote);
				else
				{
					nextNote.mustPress = true;
					playerStrums.pushNote(nextNote);
				}
			}

			shitNotes.splice(shitNotes.indexOf(nextNote), 1);
		}
	}

	private function holdNotes(elapsed:Float)
	{
		if (strums == null || playerStrums == null || opponentStrums == null)
			return;

		var holdArray:Array<Bool> = [
			Controls.left.state == PRESSED,
			Controls.down.state == PRESSED,
			Controls.up.state == PRESSED,
			Controls.right.state == PRESSED,
		];

		for (note in playerStrums.holdMap.keys())
		{
			note.holding = holdArray.unsafeGet(note.noteData);
			var receptor:Receptor = playerStrums.receptors.members.unsafeGet(note.noteData);
			var curHold:SustainNote = playerStrums.holdMap.get(note);
			if (!curHold.exists)
				return;

			@:privateAccess
			var crochet:FlxSprite = playerStrums._conductorCrochet;
			var hheight:Float = curHold.hold.y + curHold.hold.height + curHold.end.height;

			if (note.wasGoodHit && note.holding && (crochet.y >= curHold.hold.y && hheight <= crochet.y))
			{
				receptor.playAnim("confirm", true);

				if (note.holdTime >= note.sustainLength)
				{
					note.holdTime = note.sustainLength;
					trace('finished');
				}

				note.holdTime += elapsed * Conductor.stepCrochet;
				// trace(note.holdTime >= note.sustainLength);
				// trace(note.holdTime);
			}
		}
	}

	function onActionPressed(action:ActionType)
	{
		switch (action)
		{
			case BACK | RESET:
				return;

			case CONFIRM:
				if (FlxG.sound.music != null)
				{
					if (FlxG.sound.music.playing)
					{
						FlxG.sound.music.pause();
						if (swagShit != null && swagShit.needsVoices)
							voices.pause();
					}
					else
					{
						FlxG.sound.music.play();
						if (swagShit != null && swagShit.needsVoices)
							voices.play();
					}
				}

			default:
				if (playerStrums.botPlay)
					return;

				for (receptor in playerStrums.receptors)
				{
					if (action == receptor.action)
					{
						var data:Int = receptor.noteData;
						var lastTime:Float = Conductor.time;
						Conductor.time = FlxG.sound.music.time;

						var possibleNotes:Array<Note> = [];
						var directionList:Array<Int> = [];
						var dumbNotes:Array<Note> = [];

						playerStrums.noteGroup.forEachAlive(function(daNote:Note)
						{
							if ((daNote.noteData == data) && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit)
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
							playerStrums.destroyNote(note);
						}

						if (possibleNotes.length > 0)
						{
							for (coolNote in possibleNotes)
							{
								if (coolNote.canBeHit && !coolNote.tooLate)
									noteHit(coolNote);
							}
						}

						Conductor.time = lastTime;

						if (receptor.animation.curAnim.name != "confirm")
							receptor.playAnim('pressed');
					}
				}
		}
	}

	function onActionReleased(action:ActionType)
	{
		switch (action)
		{
			case BACK | CONFIRM | RESET:
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

	private function noteHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			var receptor:Receptor = playerStrums.receptors.members[note.noteData];
			note.wasGoodHit = true;
			receptor.playAnim('confirm', true);

			if (!note.isSustain)
				playerStrums.destroyNote(note);
		}
	}
}
