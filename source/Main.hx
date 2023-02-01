package;

import base.Controls;
import base.SaveData;
import base.display.*;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.system.scaleModes.FixedScaleAdjustSizeScaleMode;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
#if cpp
import cpp.NativeGc;
#end

class Main extends Sprite
{
	var gameWidth:Int = 1280;
	var gameHeight:Int = 720;
	var initialClass:Class<FlxState> = Init;
	var zoom:Float = -1;
	var framerate:Int = #if !html5 250 #else 60 #end;
	var skipSplash:Bool = true;
	var startFullscreen:Bool = false;

	public static var fpsCounter:FramerateCounter;
	public static var memoryCounter:MemoryCounter;
	public static var debugCounter:DebugCounter;

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

		#if cpp
		NativeGc.enable(true);
		#end

		// I Love sucking cocks
		FlxGraphic.defaultPersist = true;
		Controls.init();
		addChild(new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, skipSplash, startFullscreen));

		Lib.current.stage.align = TOP_LEFT;
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		// ayooo this looks sicks af bro
		FlxG.scaleMode = new FixedScaleAdjustSizeScaleMode();

		FlxG.fixedTimestep = false;
		#if !android
		FlxG.autoPause = false;
		FlxG.mouse.visible = true;
		FlxG.mouse.useSystemCursor = true;
		#end

		fpsCounter = new FramerateCounter(10, 8);
		fpsCounter.width = gameWidth;
		addChild(fpsCounter);
		if (fpsCounter != null)
			fpsCounter.visible = true;

		memoryCounter = new MemoryCounter(10, (fpsCounter.textHeight + fpsCounter.y) - 1);
		memoryCounter.width = gameWidth;
		addChild(memoryCounter);
		if (memoryCounter != null)
			memoryCounter.visible = true;

		debugCounter = new DebugCounter(10, (memoryCounter.textHeight + memoryCounter.y) + 14);
		debugCounter.width = gameWidth;
		addChild(debugCounter);
		if (debugCounter != null)
			debugCounter.visible = true;

		FlxG.save.bind("funkin_engine", "sanicbtw");
		SaveData.loadSettings();
	}
}
