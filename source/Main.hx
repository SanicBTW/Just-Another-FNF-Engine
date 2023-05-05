package;

import flixel.*;
import flixel.graphics.FlxGraphic;
import flixel.system.scaleModes.*;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import soloud.Soloud;
import window.debug.*;

class Main extends Sprite
{
	private var gameWidth:Int = 1280;
	private var gameHeight:Int = 720;
	private var initialClass:Class<FlxState> = testing.State;
	private var zoom:Float = -1;
	private var framerate:Int = 60;

	public static var fpsCounter:FramerateCounter;
	public static var memoryCounter:MemoryCounter;

	@:unreflective public static var soloud:Soloud;

	public static function main()
		Lib.current.addChild(new Main());

	public function new()
	{
		super();

		soloud = Soloud.create();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event)
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		soloud.init();
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

		addChild(new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, true, false));

		Lib.current.stage.align = TOP_LEFT;
		Lib.current.stage.scaleMode = openfl.display.StageScaleMode.NO_SCALE;

		FlxG.save.close();
		FlxG.fixedTimestep = false;
		#if !android
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		FlxG.mouse.useSystemCursor = true;
		#end

		fpsCounter = new FramerateCounter(10, 8);
		fpsCounter.width = gameWidth;
		addChild(fpsCounter);

		memoryCounter = new MemoryCounter(10, (fpsCounter.textHeight + fpsCounter.y) - 1);
		memoryCounter.width = gameWidth;
		addChild(memoryCounter);
	}
}
