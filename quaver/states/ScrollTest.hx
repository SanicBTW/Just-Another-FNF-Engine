package states;

import backend.*;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxTiledSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import network.pocketbase.User;
import openfl.display.BlendMode;

class ScrollTest extends FlxState
{
	var Controls:Controls = new Controls();
	var Paths:IsolatedPaths = new IsolatedPaths('quaver');
	var Conductor:Conductor = new Conductor();

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var camBG:FlxCamera;
	var camOther:FlxCamera;

	var accum:Float = 0;
	var gridBackground:FlxTiledSprite;
	var boardPattern:FlxTiledSprite;

	// aye i will change the dumb password wen i finish them online servers and support shit
	var user:User = new User({identity: 'sanco', password: 'fakepor9'});

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

		generateBackground();

		// Automatic update haha
		add(Conductor);

		user.schedule.push(() ->
		{
			var sex:UserCard = new UserCard(10, FlxG.width / 6, user);
			sex.cameras = [camHUD];
			add(sex);
		});
		user.getAvatar();

		FlxG.camera.zoom = 1;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		gridBackground.scrollX += (elapsed / (1 / Main.framerate)) * 0.5;
		var increaseUpTo:Float = gridBackground.height / 8;
		gridBackground.scrollY = Math.sin(accum / increaseUpTo) * increaseUpTo;
		accum += (elapsed / (1 / Main.framerate)) * 0.5;
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
	}
}
