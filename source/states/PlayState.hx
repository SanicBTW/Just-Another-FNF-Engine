package states;

import base.FadeTransition;
import base.MusicBeatState;
import base.ScriptableState;
import base.system.Conductor;
import base.system.Controls;
import base.system.DiscordPresence;
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
import flixel.util.FlxTimer;
import funkin.Character;
import funkin.ChartLoader;
import funkin.CoolUtil;
import funkin.Input.*;
import funkin.Stage;
import funkin.Timings;
import funkin.notes.Note;
import funkin.notes.Receptor;
import funkin.notes.StrumLine;
import funkin.ui.UI;
import openfl.media.Sound;
import substates.PauseState;

using StringTools;

// Look into a way of sharing input
class PlayState extends MusicBeatState
{
	// Instance to access non-static variables
	public static var instance:PlayState;

	// Cameras
	private var camGame:FlxCamera;
	private var camHUD:FlxCamera;
	private var camOther:FlxCamera;

	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	private var lastSection:Int = 0;
	private var camDisplaceX:Float = 0;
	private var camDisplaceY:Float = 0;

	private var camDisp:Float = 15;

	// Strum handling
	private var strumLines:FlxTypedGroup<StrumLine>;

	public var playerStrums:StrumLine;
	public var opponentStrums:StrumLine;

	// Countdown
	public var startedCountdown:Bool = false;
	public var startingSong:Bool = false;

	// Stage, UI and characters
	public static var stageBuild:Stage;

	private var ui:UI;

	private var player:Character;
	private var opponent:Character;
	private var girlfriend:Character;

	// Pause shit
	public static var paused:Bool = false;
	public static var canPause:Bool = true;

	// Misc
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
		camGame.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);
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

		Paths.music("tea-time");
		FadeTransition.nextCamera = camOther;
		DiscordPresence.changePresence('Playing ${SONG.song}');

		super.create();

		setupIntro();
	}

	override public function update(elapsed:Float)
	{
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

		// look into this
		playerStrums.allNotes.forEachAlive((coolNote:Note) ->
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

		if (player != null
			&& (player.holdTimer > Conductor.stepCrochet * (player.singDuration / 1000) && (!keys.contains(true) || playerStrums.botPlay)))
		{
			if (player.animation.curAnim.name.startsWith("sing") && !player.animation.curAnim.name.endsWith("miss"))
				player.dance();
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

		var inputNote:Note = handlePress(action, playerStrums, player);
		if (inputNote != null)
			noteHit(inputNote);
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);

		handleRelease(action, playerStrums);
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

		for (strumLine in strumLines)
		{
			for (i in 0...strumLine.receptors.length)
			{
				var receptor:Receptor = strumLine.receptors.members[i];
				FlxTween.tween(strumLine.receptors.members[i], {y: receptor.initialY, alpha: receptor.setAlpha}, (Conductor.crochet * 4) / 1000,
					{ease: FlxEase.circOut, startDelay: (Conductor.crochet / 1000) + ((Conductor.stepCrochet / 1000) * i)});
			}
		}
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
		var startTimer:FlxTimer = new FlxTimer().start(Conductor.crochet / 1000, (tmr:FlxTimer) ->
		{
			if (countdown >= 0 && countdown < introArray.length)
			{
				var introSprite:FlxSprite = new FlxSprite().loadGraphic(introArray[countdown]);
				introSprite.scrollFactor.set();
				introSprite.updateHitbox();
				introSprite.screenCenter();
				introSprite.cameras = [camHUD];
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
		SONG = ChartLoader.loadChart(this, (loadSong != null ? loadSong : ""), 2);

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

	private function botHit(note:Note)
	{
		var curStrums:StrumLine = (note.mustPress ? playerStrums : opponentStrums);
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			getReceptor(curStrums, note.noteData).playAnim('confirm');

			if (note.isSustain)
				getReceptor(curStrums, note.noteData).resetAnim = note.children.length;
			else
				playSplash(curStrums, note.noteData);

			if (SONG.needsVoices)
				Conductor.boundVocals.volume = 1;

			if (!note.isSustain)
				curStrums.destroyNote(note);
		}
	}

	private function noteMiss(note:Note)
	{
		if (SONG.needsVoices)
			Conductor.boundVocals.volume = 0;
	}

	private inline function getReceptor(strumLine:StrumLine, noteData:Int):Receptor
		return strumLine.receptors.members[noteData];

	private function playSplash(strumLine:StrumLine, noteData:Int)
		strumLine.splashNotes.members[noteData].playAnim();
}
