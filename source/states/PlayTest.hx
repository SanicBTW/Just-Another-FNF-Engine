package states;

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
import shader.*;
import shader.Noise.NoiseShader;
import substates.PauseState;

using StringTools;

class PlayTest extends MusicBeatState
{
	// Instance to access non-static variables
	public static var instance:PlayTest;

	// Cameras
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	// Camera target
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	// For the dynamic camera movement
	private var lastSection:Int = 0;
	private var camDisplaceX:Float = 0;
	private var camDisplaceY:Float = 0;

	private var camDisp:Float = 18;

	// Strum handling
	private var strumLines:FlxTypedGroup<StrumLine>;

	public var playerStrums:StrumLine;
	public var opponentStrums:StrumLine;

	// Countdown
	public var startedCountdown:Bool = false;
	public var startingSong:Bool = false;

	private var startTimer:FlxTimer;

	// Stage, UI and characters
	public static var stageBuild:Stage;

	private var ui:UI;

	private var player:Character;
	private var opponent:Character;
	private var girlfriend:Character;

	// Pause handling
	public static var paused:Bool = false;
	public static var canPause:Bool = true;

	// Input
	private static var receptorActionList:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

	private var keys:Array<Bool> = [false, false, false, false];

	// Shaders / Misc shit
	private var shaderFilter:ShaderFilter;
	private var pixelShader:PixelEffect;
	private var noiseShader:NoiseShader;

	public var loadSong:Null<String> = "";

	private var SONG(get, null):Song;

	@:noCompletion
	private function get_SONG():Song
		return Conductor.boundData;

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

		opponentStrums = new StrumLine((FlxG.width / 2) - separation, 4);
		opponentStrums.botPlay = true;
		opponentStrums.visible = !SaveData.middleScroll;
		opponentStrums.onBotHit.add(botHit);
		strumLines.add(opponentStrums);

		playerStrums = new StrumLine(SaveData.middleScroll ? (FlxG.width / 2) : (FlxG.width / 2) + separation, 4);
		playerStrums.onBotHit.add(botHit);
		playerStrums.onMiss.add(noteMiss);
		strumLines.add(playerStrums);

		add(strumLines);

		girlfriend = new Character(400, 130, false, "gf");
		player = new Character(770, 100, true, "bf");
		opponent = new Character(100, 100, false, "dad");

		if (!SaveData.onlyNotes)
		{
			stageBuild = new Stage("stage");
			add(stageBuild);

			girlfriend.scrollFactor.set(0.95, 0.95);
			add(girlfriend);
			add(player);
			add(opponent);
		}

		ui = new UI(player, opponent);
		ui.cameras = [camHUD];
		add(ui);

		var camPos:FlxPoint = new FlxPoint(0, 0);

		if (!SaveData.onlyNotes)
			camPos.set(player.x + (player.width / 2), player.y + (player.height / 2));

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);

		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = (stageBuild != null) ? stageBuild.cameraZoom : 1;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		applyShader(SaveFile.get("shader") != null ? SaveFile.get("shader") : "Disable");
		Paths.music("tea-time"); // precache the sound lol
		DiscordPresence.changePresence('Playing ${SONG.song}');

		super.create();

		FadeTransition.nextCamera = camOther;

		setupIntro();
	}

	override function update(elapsed:Float)
	{
		if (noiseShader != null)
			noiseShader.elapsed.value = [FlxG.game.ticks / 1000];

		var lerpVal:Float = (elapsed * 2.4);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		FlxG.camera.zoom = FlxMath.lerp((stageBuild != null) ? stageBuild.cameraZoom : 1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));

		updateCamTarget(elapsed);

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

		if (!paused)
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

		playerStrums.allNotes.forEachAlive(function(coolNote:Note)
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

		if (player != null
			&& (player.holdTimer > Conductor.stepCrochet * 0.001 * player.singDuration && (!keys.contains(true) || playerStrums.botPlay)))
		{
			if (player.animation.curAnim.name.startsWith("sing") && !player.animation.curAnim.name.endsWith("miss"))
				player.dance();
		}

		if (Timings.health <= 0)
		{
			ScriptableState.switchState(new PlayTest(loadSong));
		}
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (action == "confirm" && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			openSubState(new PauseState());
			return;
		}

		if (playerStrums.botPlay || !receptorActionList.contains(action))
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

		playerStrums.allNotes.forEachAlive(function(daNote:Note)
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
				if (keys[coolNote.noteData] && coolNote.canBeHit && !coolNote.tooLate)
					noteHit(coolNote);
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

		@:privateAccess
		ui.healthTracker.beatHit();

		if (curBeat % 2 == 0 && !SaveData.onlyNotes)
		{
			if (player.animation.curAnim.name.startsWith("idle")
				|| player.animation.curAnim.name.startsWith("dance")
				&& !player.animation.curAnim.name.startsWith("sing"))
				player.dance();
			if (opponent.animation.curAnim.name.startsWith("idle")
				|| opponent.animation.curAnim.name.startsWith("dance")
				&& !opponent.animation.curAnim.name.startsWith("sing"))
				opponent.dance();
			if (girlfriend.animation.curAnim.name.startsWith("idle")
				|| girlfriend.animation.curAnim.name.startsWith("dance")
				&& !girlfriend.animation.curAnim.name.startsWith("sing"))
				girlfriend.dance();
		}

		if (curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.05;
		}

		if (SONG.notes[Std.int(curStep / 16)] != null && SONG.notes[Std.int(curStep / 16)].changeBPM)
			Conductor.changeBPM(SONG.notes[Std.int(curStep / 16)].bpm);
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (!paused)
		{
			if (Conductor.boundSong != null)
			{
				Conductor.boundSong.pause();
				if (SONG.needsVoices)
					Conductor.boundVocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;

			DiscordPresence.changePresence('Playing ${SONG.song}', "Paused");
			paused = true;
			canPause = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			Conductor.resyncTime();

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;

			DiscordPresence.changePresence('Playing ${SONG.song}');
			paused = false;
			canPause = true;
		}

		super.closeSubState();
	}

	private function setupIntro()
	{
		Conductor.songPosition = -(Conductor.crochet * 16);
		ui.alpha = 0;
		startingSong = true;
		startCountdown();
	}

	private function startCountdown()
	{
		Conductor.songPosition = -(Conductor.crochet * 5);
		startedCountdown = true;

		FlxTween.tween(ui, {alpha: 1}, (Conductor.crochet * 2) / 1000, {startDelay: (Conductor.crochet / 1000)});

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
			if (!SaveData.onlyNotes)
			{
				if (girlfriend != null
					&& tmr.loopsLeft % girlfriend.danceEveryNumBeats == 0
					&& girlfriend.animation.curAnim.name != null
					&& !girlfriend.animation.curAnim.name.startsWith("sing"))
					girlfriend.dance();

				if (tmr.loopsLeft % player.danceEveryNumBeats == 0
					&& player.animation.curAnim.name != null
					&& !player.animation.curAnim.name.startsWith("sing"))
					player.dance();

				if (tmr.loopsLeft % opponent.danceEveryNumBeats == 0
					&& opponent.animation.curAnim.name != null
					&& !opponent.animation.curAnim.name.startsWith("sing"))
					opponent.dance();
			}

			if (countdown >= 0 && countdown < introArray.length)
			{
				var introSprite:FlxSprite = new FlxSprite().loadGraphic(introArray[countdown]);
				introSprite.scrollFactor.set();
				introSprite.updateHitbox();
				introSprite.screenCenter();
				introSprite.antialiasing = SaveData.antialiasing;
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
		ChartLoader.loadChart((loadSong != null ? loadSong : ""), 2);
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

	private function updateCamTarget(elapsed:Float)
	{
		var curSection = Std.int(curStep / 16);
		if (curSection != lastSection)
		{
			if (SONG.notes[lastSection] != null && (SONG.notes[curSection].mustHitSection != SONG.notes[lastSection].mustHitSection))
			{
				camDisplaceX = 0;
				camDisplaceY = 0;
				lastSection = Std.int(curStep / 16);
			}
		}

		if (!SaveData.onlyNotes)
		{
			updateCamFollow(elapsed);
			cameraDisplacement(player, true);
			cameraDisplacement(opponent, false);
		}
	}

	private function updateCamFollow(?elapsed:Float)
	{
		if (elapsed == null)
			elapsed = FlxG.elapsed;

		var mustHit:Bool = SONG.notes[Std.int(curStep / 16)].mustHitSection;
		var char:Character = (mustHit ? player : opponent);
		var charCenterX:Float = char.getMidpoint().x;
		var charCenterY:Float = char.getMidpoint().y;

		var centerX = (mustHit ? charCenterX - 100 : charCenterX + 150);
		var centerY = (mustHit ? charCenterY - 100 : charCenterY - 100);
		var newX:Float = (mustHit ? (camDisplaceX - char.cameraPosition.x) : (camDisplaceX + char.cameraPosition.x));
		var newY:Float = camDisplaceY + char.cameraPosition.y;

		camFollow.setPosition(centerX, centerY);
		camFollow.x += newX;
		camFollow.y += newY;
	}

	private function cameraDisplacement(character:Character, mustHit:Bool)
	{
		if (SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (SONG.notes[Std.int(curStep / 16)].mustHitSection
				&& mustHit
				|| (!SONG.notes[Std.int(curStep / 16)].mustHitSection && !mustHit))
			{
				if (character.animation.curAnim != null)
				{
					camDisplaceX = 0;
					camDisplaceY = 0;
					switch (character.animation.curAnim.name)
					{
						case 'singUP':
							camDisplaceY -= camDisp;
						case 'singDOWN':
							camDisplaceY += camDisp;
						case 'singLEFT':
							camDisplaceX -= camDisp;
						case 'singRIGHT':
							camDisplaceX += camDisp;
					}
				}
			}
		}
	}

	private function noteHit(note:Note)
	{
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			getReceptor(playerStrums, note.noteData).playAnim('confirm', true);

			if (!note.isSustain)
			{
				var rating:String = Timings.judge(-(note.strumTime - Conductor.songPosition));
				if (rating == "marvelous" || rating == "sick")
					playSplash(playerStrums, note.noteData);
			}
			else
				Timings.judge(Timings.judgements[0].timing, true);

			if (!note.doubleNote)
			{
				if (player != null)
				{
					player.playAnim('sing${Receptor.getArrowFromNum(note.noteData).toUpperCase()}', true);
					player.holdTimer = 0;
				}
			}
			else
				trail(player, note);

			if (SONG.needsVoices)
				Conductor.boundVocals.volume = 1;

			if (!note.isSustain)
				playerStrums.destroyNote(note);

			ui.updateText();
		}
	}

	private function noteMiss(note:Note)
	{
		if (SONG.needsVoices)
			Conductor.boundVocals.volume = 0;

		if (player != null)
		{
			player.playAnim('sing${Receptor.getArrowFromNum(note.noteData).toUpperCase()}miss', true);
			player.holdTimer = 0;
		}

		Timings.judge(164);
		ui.updateText();
	}

	private function botHit(note:Note)
	{
		var curStrums:StrumLine = (note.mustPress ? playerStrums : opponentStrums);
		var curChar:Character = (note.mustPress ? player : opponent);
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			getReceptor(curStrums, note.noteData).playAnim('confirm', true);

			if (!note.isSustain)
				playSplash(curStrums, note.noteData);

			if (!note.doubleNote)
			{
				if (curChar != null)
				{
					curChar.playAnim('sing${Receptor.getArrowFromNum(note.noteData).toUpperCase()}', true);
					curChar.holdTimer = 0;
				}
			}
			else
				trail(curChar, note);

			if (SONG.needsVoices)
				Conductor.boundVocals.volume = 1;

			if (!note.isSustain)
				curStrums.destroyNote(note);
			else
			{
				if (curChar == null)
					return;

				var targetHold:Float = Conductor.stepCrochet * 0.001 * curChar.singDuration;
				if (curChar.holdTimer + 0.2 > targetHold)
					curChar.holdTimer = targetHold - 0.2;
			}
		}
	}

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];

	private function playSplash(strumLine:StrumLine, noteData:Int)
		strumLine.splashNotes.members[noteData].playAnim();

	function trail(char:Character, note:Note):Void
	{
		if (!SaveData.showTrails || char == null || note.isSustain)
			return;

		var anim:String = 'sing${Receptor.getArrowFromNum(note.noteData).toUpperCase()}';

		var daCopy:FlxSprite = char.clone();
		daCopy.frames = char.frames;
		daCopy.animation.copyFrom(char.animation);
		daCopy.alpha = 0.6;
		daCopy.setPosition(char.x, char.y);
		daCopy.animation.play(anim, true);
		daCopy.offset.set(char.animOffsets[anim][0], char.animOffsets[anim][1]);

		insert(members.indexOf(char) - 1, daCopy);
		FlxTween.tween(daCopy, {alpha: 0}, Conductor.stepCrochet * 0.001 * char.singDuration, {
			ease: FlxEase.quadInOut,
			onComplete: function(_)
			{
				daCopy.destroy();
				daCopy = null;
			}
		});
	}

	function applyShader(shader:String)
	{
		if (shaderFilter != null)
			shaderFilter = null;

		if (pixelShader != null)
			pixelShader = null;

		if (noiseShader != null)
			noiseShader = null;

		switch (shader)
		{
			case "Drug":
				shaderFilter = new ShaderFilter(new CoolShader());
			case "Pixel":
				pixelShader = new PixelEffect();
				pixelShader.PIXEL_FACTOR = 1024.;
				shaderFilter = new ShaderFilter(pixelShader.shader);
			case "Noise":
				noiseShader = new NoiseShader();
				shaderFilter = new ShaderFilter(noiseShader);
			case "Disable":
				FlxG.camera.setFilters([]);
		}

		if (shaderFilter != null)
			FlxG.game.setFilters([shaderFilter]);
	}
}
