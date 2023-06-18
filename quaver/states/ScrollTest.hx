package states;

import backend.*;
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

	// aye i will change the dumb password wen i finish them online servers and support shit
	var user:User = new User({identity: 'sanco', password: 'fakepor9'});
	var qua:Qua = null;

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

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther, false);

		// Automatic update haha
		// Gotta create it on create (haha i want to kms) because of some issue with them signals and events lol
		Conductor = new Conductor();
		add(Conductor);

		generateBackground();
		generateChart();
		loadUser();

		FlxG.camera.zoom = 1;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		super.create();
	}

	override function update(elapsed:Float)
	{
		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));

		super.update(elapsed);

		gridBackground.scrollX += (elapsed / (1 / FlxG.drawFramerate)) * 0.5;
		var increaseUpTo:Float = gridBackground.height / 8;
		gridBackground.scrollY = Math.sin(accum / increaseUpTo) * increaseUpTo;
		accum += (elapsed / (1 / FlxG.drawFramerate)) * 0.5;
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

		strums = new StrumLine((FlxG.width / 2) + FlxG.width / 4, 50);
		strums.cameras = [camHUD];
		add(strums);
	}

	function generateChart()
	{
		qua = new Qua(Cache.getText(Paths.getPath('107408/107408.qua')));
		FlxG.sound.playMusic(Cache.getSound(#if FS_ACCESS LocalPaths.getPath('${qua.MapId}/${qua.AudioFile}') #else Paths.getPath('${qua.MapId}/${qua.AudioFile}') #end));
		Conductor.bpm = qua.TimingPoints[0].Bpm;

		Conductor.onBeatHit.add((curBeat) ->
		{
			if (curBeat % 4 == 0)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}
		});
	}

	function loadUser()
	{
		user.schedule.push(() ->
		{
			var sex:UserCard = new UserCard(10, FlxG.width / 12, user);
			sex.cameras = [camHUD];
			add(sex);
		});
		user.getAvatar();
	}
}
