package states;

import backend.*;
import backend.Conductor.BPMChange;
import backend.Controls.ActionType;
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
import hxkv.Hxkv;
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

using backend.Extensions;

class ScrollTest extends FlxState
{
	public static var Controls:Controls = new Controls();
	public static var Paths:IsolatedPaths = new IsolatedPaths('quaver');
	public static var LocalPaths:IsolatedPaths = new IsolatedPaths(haxe.io.Path.join([lime.system.System.documentsDirectory, "just_another_fnf_engine", "quaver"]));
	public static var Conductor:Conductor;
	public static var Settings:Hxkv = new Hxkv("jafe_settings");

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var camBG:FlxCamera;
	var camOther:FlxCamera;

	var accum:Float = 0;
	var gridBackground:FlxTiledSprite;

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
		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));
		strumCam.zoom = FlxMath.lerp(1, strumCam.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));

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

		if (gridBackground != null)
		{
			gridBackground.scrollX += (elapsed / (1 / FlxG.drawFramerate)) * 0.5;
			var increaseUpTo:Float = gridBackground.height / 8;
			gridBackground.scrollY = Math.sin(accum / increaseUpTo) * increaseUpTo;
			accum += (elapsed / (1 / FlxG.drawFramerate)) * 0.5;
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
		gridBackground = new FlxTiledSprite(Paths.image('chart/gridPurple'), FlxG.width, FlxG.height);
		gridBackground.cameras = [camBG];
		add(gridBackground);

		var background:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			[FlxColor.fromRGB(167, 103, 225), FlxColor.fromRGB(137, 20, 181)]);
		background.alpha = 0.6;
		background.cameras = [camBG];
		add(background);

		// dark background
		var darkBackground:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		darkBackground.setGraphicSize(Std.int(FlxG.width));
		darkBackground.cameras = [camBG];
		darkBackground.scrollFactor.set();
		darkBackground.screenCenter();
		darkBackground.alpha = 0.7;
		add(darkBackground);

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
	}

	function generateChart()
	{
		qua = new Qua(Cache.getText(Paths.getPath('79274/79274.qua')));
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
			newNote.strumLine = 0;
			newNote.sustainLength = (endTime > 0) ? Math.floor((endTime - startTime)) + 1 : 0;
			shitNotes.push(newNote);
		}
		generateBackground();
		/*
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

				var curChange:BPMChange = {
					stepTime: 0,
					songTime: 0,
					bpm: swagShit.bpm,
					stepCrochet: Conductor.stepCrochet
				};
				var curBPM:Float = swagShit.bpm;
				var totalSteps:Int = 0;
				var totalPos:Float = 0;

				for (section in swagShit.notes)
				{
					if (section.changeBPM && section.bpm != curBPM)
					{
						curBPM = section.bpm;
						var bpmChange:BPMChange = {
							stepTime: totalSteps,
							songTime: totalPos,
							bpm: curBPM,
							stepCrochet: ((60 / curBPM) * 1000) / 4
						};
						Conductor.bpmChanges.push(bpmChange);
						curChange = bpmChange;
					}

					for (songNotes in section.sectionNotes)
					{
						switch (songNotes[1])
						{
							default:
								var stepTime:Float = (songNotes[0] / curChange.stepCrochet);
								var sustainTime:Float = 0;
								var noteData:Int = Std.int(songNotes[1] % 4);
								var hitNote:Bool = section.mustHitSection;

								if (songNotes[2] > 0)
									sustainTime = (songNotes[2] / curChange.stepCrochet);

								if (songNotes[1] > 3)
									hitNote = !section.mustHitSection;

								var strumLine:Int = (hitNote ? 1 : 0);

								var oldNote:Note = null;
								if (shitNotes.length > 0)
									oldNote = shitNotes[shitNotes.length - 1];

								var newNote:Note = new Note(stepTime, noteData, oldNote, false);
								newNote.mustPress = hitNote;
								newNote.strumLine = strumLine;
								newNote.sustainLength = (sustainTime > 0) ? Math.floor(sustainTime) + 1 : 0;
								shitNotes.push(newNote);

							case -1:
								return;
						}
					}
				}

				shitNotes.sort((a, b) ->
				{
					return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
				});

				generateBackground();
				Conductor.active = false;
			});

			PBRequest.getRecords('funkin', (funky:Collection<FunkinRecord>) ->
			{
				var ghost:FunkinRecord = {
					chart: 'ghost_hard_JEoWzLBa1G.json',
					collectionId: '9id75c79c70m6yq',
					collectionName: 'funkin',
					created: Date.fromString("2023-05-23 02:10:06"),
					id: 'penevsvaginaxdd',
					inst: 'inst_2VIHB5dcGM.ogg',
					song: 'ghost',
					updated: Date.fromString("2023-05-23 02:10:06"),
					voices: "voices_AH40sP1G4A.ogg"
				};

				var selected:FunkinRecord = funky.items.randomElementExcept(ghost, true);

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
		});*/

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

	private function holdNotes(elapsed:Float)
	{
		if (strums == null)
			return;

		var holdArray:Array<Bool> = [
			Controls.left.state == PRESSED,
			Controls.down.state == PRESSED,
			Controls.up.state == PRESSED,
			Controls.right.state == PRESSED,
		];

		// Look into this
		/*
			for (note in playerStrums.holdMap.keys())
			{
				var isHeld:Bool = holdArray[note.noteData];
				var receptor:Receptor = playerStrums.receptors.members[note.noteData];
				if (isHeld && receptor.animation.curAnim.name != "confirm")
					receptor.playAnim("confirm", true);
		}*/
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
