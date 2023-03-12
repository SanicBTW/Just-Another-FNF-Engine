package;

import base.ScriptableState;
import base.display.*;
import base.system.Controls;
import base.system.DatabaseManager;
import base.ui.VolumeTray;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.system.scaleModes.*;
import lime.app.Application;
import openfl.Lib;
import openfl.display.Graphics;
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
	var framerate:Int = #if !html5 120 #else 60 #end;
	var skipSplash:Bool = true;
	var startFullscreen:Bool = false;

	public static var fpsCounter:FramerateCounter;
	public static var memoryCounter:MemoryCounter;
	public static var volumeTray:VolumeTray;

	public static var gfxSprite(default, null):Sprite = new Sprite();
	public static var gfx(default, null):Graphics = gfxSprite.graphics;

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
		DatabaseManager.Initialize();
		Controls.init();

		Application.current.window.title = 'BETA ${Application.current.meta.get("version")}';
		FlxGraphic.defaultPersist = true;
		ScriptableState.skipTransIn = true;
		addChild(new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, skipSplash, startFullscreen));

		// FlxG.scaleMode = new FixedScaleAdjustSizeScaleMode();

		Lib.current.stage.align = TOP_LEFT;
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		FlxG.fixedTimestep = false;
		#if !android
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
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

		volumeTray = new VolumeTray();
		addChild(volumeTray);

		FlxG.signals.preStateCreate.add(function(state:FlxState)
		{
			Cache.clearStoredMemory();
			FlxG.bitmap.dumpCache();
			Cache.runGC();
		});

		FlxG.signals.preStateSwitch.add(function()
		{
			Cache.clearUnusedMemory();
			Cache.runGC();
		});

		FlxG.signals.gameResized.add((_, _) ->
		{
			if (volumeTray != null)
				volumeTray.screenCenter();
		});

		Lib.application.onUpdate.add((_) ->
		{
			if (volumeTray != null && volumeTray.active)
				volumeTray.update();
		});
	}
}
