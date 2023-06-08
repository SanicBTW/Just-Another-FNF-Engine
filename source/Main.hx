package;

import backend.*;
import flixel.*;
import flixel.graphics.FlxGraphic;
import flixel.system.scaleModes.*;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;

using StringTools;

class Main extends Sprite
{
	private var gameWidth:Int = 1280;
	private var gameHeight:Int = 720;
	private var initialClass:Class<FlxState> = test.QuaverTest;
	private var zoom:Float = -1;
	private var framerate:Int = lime.system.System.getDisplay(0).currentMode.refreshRate; // VSync :troll:

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

		// Enable GCs
		#if cpp
		cpp.vm.Gc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end

		Save.Initialize();
		Controls.Initialize();
		IO.Initialize();
		DiscordPresence.Initialize();
		ScriptHandler.Initialize();
		setupGame();

		FlxG.signals.preStateCreate.add((_) ->
		{
			Cache.clearStoredMemory();
			Cache.clearUnusedMemory();
			FlxG.bitmap.dumpCache();
			Cache.collect();
		});

		#if sys
		for (arg in Sys.args())
		{
			if (arg.contains("-enable_gpu_rendering"))
				Cache.gpuRender = true;

			if (arg.contains("-fps"))
				setFPS(Std.parseInt(arg.split(":")[1]));
		}
		#end
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

		FlxGraphic.defaultPersist = true;
		addChild(new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, true, false));

		// FlxG.scaleMode = new FixedScaleAdjustSizeScaleMode();
		FlxG.fixedTimestep = false;
		#if !android
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		FlxG.mouse.useSystemCursor = true;
		#end
	}

	public static function setFPS(newFPS:Int)
	{
		Lib.current.stage.frameRate = newFPS;
		if (newFPS > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = newFPS;
			FlxG.drawFramerate = newFPS;
		}
		else
		{
			FlxG.drawFramerate = newFPS;
			FlxG.updateFramerate = newFPS;
		}
	}
}
