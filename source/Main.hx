package;

import base.Controls;
import base.SaveData;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;

class Main extends Sprite
{
	var gameWidth:Int = 1280;
	var gameHeight:Int = 720;
	var initialClass:Class<FlxState> = Init;
	var zoom:Float = -1;
	var framerate:Int = 60;
	var skipSplash:Bool = true;
	var startFullscreen:Bool = false;

	public static var fpsCounter:FPS;

	public static function main()
		Lib.current.addChild(new Main());

	public function new()
	{
		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event)
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame()
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		// I Love sucking cocks
		FlxGraphic.defaultPersist = true;
		Controls.init();
		addChild(new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, skipSplash, startFullscreen));

		Lib.current.stage.align = TOP_LEFT;
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		FlxG.fixedTimestep = false;
		#if !android
		FlxG.autoPause = false;
		FlxG.mouse.visible = true;
		FlxG.mouse.useSystemCursor = true;
		#end

		fpsCounter = new FPS(10, 8, 0xFFFFFF);
		fpsCounter.width = gameWidth;
		addChild(fpsCounter);
		if (fpsCounter != null)
		{
			fpsCounter.visible = true;
		}

		FlxG.save.bind("funkin_engine", "sanicbtw");
		SaveData.loadSettings();
	}
}
