package test;

import Paths.Libraries;
import backend.Cache;
import backend.Controls;
import base.Conductor;
import base.MusicBeatState;
import base.ScriptableState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import funkin.ChartLoader;
import funkin.ChartLoader;
import funkin.Timings;
import funkin.UI;
import funkin.notes.Note;
import funkin.notes.Receptor;
import funkin.notes.StrumLine;
import lime.graphics.Image;
import lime.utils.Assets;
import network.Request;
import network.pocketbase.Collection;
import network.pocketbase.Record;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.media.Sound;
import quaver.QuaverMap;
import transitions.FadeTransition;

using StringTools;

// goofy code gotta order it bruh
class QuaverTest extends MusicBeatState
{
	// Cameras
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	public var strums:StrumLine;

	// Countdown
	public var startedCountdown:Bool = false;
	public var startingSong:Bool = false;

	private var startTimer:FlxTimer;

	// Them input
	private final actionList:Array<Action> = [Action.NOTE_LEFT, Action.NOTE_DOWN, Action.NOTE_UP, Action.NOTE_RIGHT];

	var cellSize:Int = 70;
	var totalElapsed:Float = 0;

	var gridBackground:FlxTiledSprite;
	var boardPattern:FlxTiledSprite;

	public static var map:QuaverMap = null;

	override public function create()
	{
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			FlxG.sound.music.stop();

		Controls.targetActions = NOTES;
		Timings.call();

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

		generateBackground();

		strums = new StrumLine((FlxG.width / 2), FlxG.height / 6);
		strums.botPlay = true;
		strums.onBotHit.add(botHit);
		strums.onMiss.add(noteMiss);
		strums.cameras = [camHUD];
		add(strums);

		QuaverParser.parse('107408');

		Conductor.songPosition = -5000;

		FlxG.camera.zoom = 1;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		setOnModules('camGame', camGame);
		setOnModules('camHUD', camHUD);
		setOnModules('PlayState', this);
		setOnModules('stepHit', stepHit);
		setOnModules('beatHit', beatHit);

		startingSong = true;

		callOnModules('onCreatePost', '');

		setupCountdown();

		super.create();

		FadeTransition.nextCamera = camOther;
	}

	override function update(elapsed:Float)
	{
		callOnModules('onUpdate', elapsed);

		if (map == null)
			return;

		super.update(elapsed);

		if (startedCountdown && startingSong)
		{
			// do not toggle update time as it will resync
			Conductor.songPosition += elapsed * 1000;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if (!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}

		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));

		while ((ChartLoader.noteQueue[0] != null) && (ChartLoader.noteQueue[0].strumTime - Conductor.songPosition) < 3500)
		{
			var nextNote:Note = ChartLoader.noteQueue[0];
			if (nextNote != null)
			{
				nextNote.mustPress = true;
				strums.push(nextNote);
				callOnModules('onSpawnNote', [
					ChartLoader.noteQueue.indexOf(nextNote),
					nextNote.noteData,
					nextNote.noteType,
					nextNote.isSustain
				]);
			}
			ChartLoader.noteQueue.splice(ChartLoader.noteQueue.indexOf(nextNote), 1);
		}

		holdNotes(elapsed);

		// better resync or something (notes lag on bot hit and shit gotta look into that)
		if (FlxG.sound.music != null && Math.abs(FlxG.sound.music.time - Conductor.songPosition) > Conductor.comparisonThreshold)
		{
			trace('Resyncing song time ${FlxG.sound.music.time}, ${Conductor.songPosition}');

			FlxG.sound.music.play();
			Conductor.songPosition = FlxG.sound.music.time;

			trace('New song time ${FlxG.sound.music.time}, ${Conductor.songPosition}');
		}

		gridBackground.scrollX += (elapsed / (1 / 60)) * 0.5;
		var increaseUpTo:Float = gridBackground.height / 8;
		gridBackground.scrollY = Math.sin(totalElapsed / increaseUpTo) * increaseUpTo;
		totalElapsed += (elapsed / (1 / 60)) * 0.5;

		callOnModules('onUpdatePost', elapsed);
	}

	override private function onActionPressed(action:String)
	{
		if (startingSong)
			return;

		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case "reset" | "confirm":
				return;

			case "back":
				FlxG.sound.music.onComplete();

			default:
				if (!strums.botPlay && startedCountdown)
				{
					for (receptor in strums.receptors)
					{
						if (action == receptor.action)
						{
							var data:Int = receptor.noteData;
							var lastTime:Float = Conductor.songPosition;
							Conductor.songPosition = FlxG.sound.music.time;

							var possibleNotes:Array<Note> = [];
							var directionList:Array<Int> = [];
							var dumbNotes:Array<Note> = [];

							strums.notesGroup.forEachAlive(function(daNote:Note)
							{
								if ((daNote.noteData == data) && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustain)
								{
									if (directionList.contains(data))
									{
										for (coolNote in possibleNotes)
										{
											if (coolNote.noteData == daNote.noteData
												&& Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
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

							Conductor.songPosition = lastTime;

							if (receptor.animation.curAnim.name != "confirm")
								receptor.playAnim('pressed');
						}
					}
				}
		}
		callOnModules('onKeyPress', action);
	}

	override private function onActionReleased(action:String)
	{
		// Check system actions and the rest of actions will be check through the strum group
		switch (action)
		{
			case "confirm" | "back" | "reset":
				return;

			default:
				if (!strums.botPlay && startedCountdown)
				{
					for (receptor in strums.receptors)
					{
						if (action == receptor.action)
						{
							receptor.playAnim('static');
						}
					}
				}
		}
		callOnModules('onKeyRelease', action);
	}

	private function holdNotes(elapsed:Float)
	{
		if (strums == null)
			return;

		var holdArray:Array<Bool> = parseKeys();

		if (!strums.botPlay)
		{
			strums.allNotes.forEachAlive(function(coolNote:Note)
			{
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

	private function setupCountdown()
	{
		for (receptor in strums.receptors)
		{
			receptor.y -= 32;
			receptor.alpha = 0;
		}

		startCountdown();
	}

	private function startCountdown()
	{
		if (startedCountdown)
		{
			callOnModules('onStartCountdown', null);
			return;
		}

		callOnModules('onStartCountdown', null);

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var i = 0;
		for (receptor in strums.receptors)
		{
			FlxTween.tween(receptor, {y: receptor.initialY, alpha: receptor.setAlpha}, (Conductor.crochet * 4) / 1000,
				{ease: FlxEase.circOut, startDelay: (Conductor.crochet / 1000) + ((Conductor.stepCrochet / 1000) * i)});
			i++;
		}

		setOnModules('startedCountdown', true);
		callOnModules('onCountdownStarted', null);

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

			callOnModules('onCountdownTick', countdown);

			countdown++;
			FlxG.sound.play(soundsArray[countdown], 0.6);
		}, 5);
	}

	private function startSong()
	{
		startingSong = false;

		FlxG.sound.music.play();
		FlxG.sound.music.onComplete = endSong.bind();

		updateTime = true;

		setOnModules('songLength', FlxG.sound.music.length);
		callOnModules('onSongStart', null);
	}

	override public function stepHit()
	{
		setOnModules('curStep', curStep);
		callOnModules('onStepHit', []);
	}

	override public function beatHit()
	{
		if (FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		setOnModules('curBeat', curBeat);
		callOnModules('onBeatHit', []);
	}

	private function noteHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			var receptor:Receptor = getReceptor(strums, note.noteData);
			note.wasGoodHit = true;
			receptor.playAnim('confirm', true);

			if (!note.isSustain)
				Timings.judge(-(note.strumTime - Conductor.songPosition));

			callOnModules('goodNoteHit', [
				ChartLoader.noteQueue.indexOf(note),
				note.noteData,
				note.noteType,
				note.isSustain
			]);

			if (!note.isSustain)
				strums.destroyNote(note);
		}
	}

	private function botHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			var receptor:Receptor = getReceptor(strums, note.noteData);
			note.wasGoodHit = true;

			var time:Float = 0.15;
			if (note.isSustain && !note.isSustainEnd)
				time += 0.15;

			receptor.playAnim('confirm', true);
			receptor.holdTimer = time;

			callOnModules("goodNoteHit", [
				ChartLoader.noteQueue.indexOf(note),
				note.noteData,
				note.noteType,
				note.isSustain
			]);

			if (!note.isSustain)
				strums.destroyNote(note);
		}
	}

	private function noteMiss(note:Note)
	{
		Timings.judge(Timings.judgements[Timings.judgements.length - 1].timing);

		callOnModules('noteMiss', [
			ChartLoader.noteQueue.indexOf(note),
			note.noteData,
			note.noteType,
			note.isSustain
		]);
	}

	private function endSong():Void
	{
		updateTime = false;
		FlxG.sound.music.stop();
		callOnModules('onEndSong', null);
	}

	function generateBackground()
	{
		gridBackground = new FlxTiledSprite(Paths.image('chart/gridPurple'), FlxG.width, FlxG.height);
		gridBackground.cameras = [camGame];
		add(gridBackground);

		var background:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			[FlxColor.fromRGB(167, 103, 225), FlxColor.fromRGB(137, 20, 181)]);
		background.alpha = 0.6;
		background.cameras = [camGame];
		add(background);

		// dark background
		var darkBackground:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		darkBackground.setGraphicSize(Std.int(FlxG.width));
		darkBackground.cameras = [camGame];
		darkBackground.scrollFactor.set();
		darkBackground.screenCenter();
		darkBackground.alpha = 0.7;
		add(darkBackground);

		// dark background
		var funkyBack:FlxSprite = new FlxSprite().loadGraphic(Paths.image('chart/bg'));
		funkyBack.setGraphicSize(Std.int(FlxG.width));
		funkyBack.cameras = [camGame];
		funkyBack.scrollFactor.set();
		funkyBack.blend = BlendMode.DIFFERENCE;
		funkyBack.screenCenter();
		funkyBack.alpha = 0.07;
		add(funkyBack);
	}

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];
}
