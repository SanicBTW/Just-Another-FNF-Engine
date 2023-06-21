package states;

import backend.*;
import backend.Controls.ActionType;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxTiledSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import network.pocketbase.User;
import openfl.display.BlendMode;
import quaver.Qua;
import quaver.notes.Note;
import quaver.notes.Receptor;
import quaver.notes.StrumLine;

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

	var accum:Float = 0;
	var gridBackground:FlxTiledSprite;

	var strums:StrumLine;
	// Dedicated cam for the strums so scrolling actually works and shit i hate my life
	var strumCam:FlxCamera;

	// aye i will change the dumb password wen i finish them online servers and support shit
	var qua:Qua = null;

	var shitNotes:Array<Note> = [];

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

		// Automatic update haha
		// Gotta create it on create (haha i want to kms) because of some issue with them signals and events lol
		Conductor = new Conductor();
		add(Conductor);

		backend.Controls.onActionPressed.add(onActionPressed);
		backend.Controls.onActionReleased.add(onActionReleased);

		generateChart();
		generateBackground();

		FlxG.camera.zoom = 1;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		super.create();
	}

	override function update(elapsed:Float)
	{
		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));

		while ((shitNotes[0] != null) && (shitNotes[0].strumTime - Conductor.time) <= camera.scroll.y + camera.height)
		{
			var nextNote:Note = shitNotes[0];
			if (nextNote != null)
				strums.pushNote(nextNote);

			shitNotes.splice(shitNotes.indexOf(nextNote), 1);
		}

		holdNotes(elapsed);

		super.update(elapsed);

		gridBackground.scrollX += (elapsed / (1 / FlxG.drawFramerate)) * 0.5;
		var increaseUpTo:Float = gridBackground.height / 8;
		gridBackground.scrollY = Math.sin(accum / increaseUpTo) * increaseUpTo;
		accum += (elapsed / (1 / FlxG.drawFramerate)) * 0.5;
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

		strums = new StrumLine((FlxG.width / 2));
		strums.cameras = [strumCam];
		add(strums);
	}

	function generateChart()
	{
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
			var holdStep:Int = newNote.sustainLength = (endTime > 0) ? Math.round((endTime - startTime) / Conductor.stepCrochet) + 1 : 0;
			shitNotes.push(newNote);

			if (holdStep > 0)
			{
				for (note in 0...holdStep)
				{
					var sustainNote:Note = new Note(startTime * note, noteData, shitNotes[shitNotes.length - 1], true);
					sustainNote.head = newNote;
					sustainNote.isSustainEnd = (note == holdStep - 1);

					newNote.tail.push(sustainNote);
					shitNotes.push(sustainNote);
				}
			}
		}

		Conductor.onBeatHit.add((curBeat) ->
		{
			if (curBeat % 4 == 0)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}
		});

		FlxG.sound.music.play(true);
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
		for (note in strums.holdMap.keys())
		{
			if (note.holdingTime < note.sustainLength && !note.tooLate && note.wasGoodHit)
			{
				var isHeld:Bool = holdArray[note.noteData];
				var receptor:Receptor = strums.receptors.members[note.noteData];
				if (isHeld && receptor.animation.curAnim.name != "confirm")
					receptor.playAnim("confirm", true);

				note.holdingTime = Conductor.time - note.strumTime;
				var regrabTime:Float = 0.2;

				if (isHeld)
					note.tripTimer = 1;
				else
					note.tripTimer -= elapsed / regrabTime; // maybe make the regrab timer an option

				if (note.tripTimer <= 0)
				{
					note.tripTimer = 0;
					trace("tripped hold / roll");
					note.tooLate = true;
					note.wasGoodHit = false;
					for (tail in note.tail)
					{
						if (!tail.wasGoodHit)
							tail.tooLate = true;
					}
				}
				else
				{
					for (tail in note.tail)
					{
						if ((tail.strumTime - 25) <= Conductor.time && !tail.wasGoodHit && !tail.tooLate)
							noteHit(tail);
					}

					if (note.holdingTime >= note.sustainLength)
					{
						trace("finished hold / roll successfully");
						note.holdingTime = note.sustainLength;
					}
				}
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
						FlxG.sound.music.pause();
					else
						FlxG.sound.music.play();
				}

			default:
				for (receptor in strums.receptors)
				{
					if (action == receptor.action)
					{
						var data:Int = receptor.noteData;
						var lastTime:Float = Conductor.time;
						Conductor.time = FlxG.sound.music.time;

						var possibleNotes:Array<Note> = [];
						var directionList:Array<Int> = [];
						var dumbNotes:Array<Note> = [];

						strums.noteGroup.forEachAlive(function(daNote:Note)
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
							strums.destroyNote(note);
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
				for (receptor in strums.receptors)
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
			var receptor:Receptor = strums.receptors.members[note.noteData];
			note.wasGoodHit = true;
			receptor.playAnim('confirm', true);

			if (!note.isSustain)
				strums.destroyNote(note);
		}
	}
}
