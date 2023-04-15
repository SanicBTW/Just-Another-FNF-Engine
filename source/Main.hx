package;

import base.ScriptableState;
import base.system.*;
import flixel.*;
import flixel.graphics.FlxGraphic;
import flixel.system.scaleModes.*;
import lime.app.Application;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import states.RewriteMenu;
import window_ui.*;
#if cpp
import cpp.vm.Gc;
#end
#if windows
import haxe.CallStack;
import haxe.io.Path;
import openfl.events.UncaughtErrorEvent;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

using StringTools;
#end

class Main extends Sprite
{
	private var gameWidth:Int = 1280;
	private var gameHeight:Int = 720;
	private var initialClass:Class<FlxState> = RewriteMenu;
	private var zoom:Float = -1;
	private var framerate:Int = 60;
	private var skipSplash:Bool = true;
	private var startFullscreen:Bool = false;

	public static var game:FlxGame;
	private static var trays:Array<Tray> = [];

	public static var fpsCounter:FramerateCounter;
	public static var memoryCounter:MemoryCounter;
	public static var volumeTray:VolumeTray;

	public static var preview:Float = 7.6;

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

		setup();
		setupGame();
	}

	private function setup()
	{
		#if cpp
		Gc.enable(true);
		#end

		Lib.current.stage.align = TOP_LEFT;

		SaveFile.Initialize();
		Controls.init();

		DiscordPresence.initPresence();
		FlxGraphic.defaultPersist = true;
		ScriptableState.skipTransIn = true;

		fpsCounter = new FramerateCounter(10, 8);
		fpsCounter.width = gameWidth;

		memoryCounter = new MemoryCounter(10, (fpsCounter.textHeight + fpsCounter.y) - 1);
		memoryCounter.width = gameWidth;

		volumeTray = new VolumeTray();
		trays.push(volumeTray);

		DragDrop.listen();

		// will add funny ? on html lol
		#if sys
		for (arg in Sys.args())
		{
			// if (arg.contains("-GPU_RENDERING"))
			//	Cache.textureCompression = true;

			if (arg.contains("-FPS"))
				setFPS(Std.parseInt(arg.split(":")[1]));

			if (arg.contains("-NO_DRPC"))
				DiscordPresence.shutdownPresence();
		}
		#end

		#if windows
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
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

		game = new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, skipSplash, startFullscreen);
		addChild(game);
		addChild(fpsCounter);
		addChild(memoryCounter);
		addChild(volumeTray);
		addChild(new TopMessage("sex", INFO));

		FlxG.scaleMode = new FixedScaleAdjustSizeScaleMode();

		FlxG.fixedTimestep = false;
		#if !android
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		FlxG.mouse.useSystemCursor = true;
		#end

		FlxG.signals.preStateCreate.add((_) ->
		{
			Cache.clearStoredMemory();
			FlxG.bitmap.dumpCache();
			Cache.runGC();
		});

		FlxG.signals.preStateSwitch.add(() ->
		{
			Cache.clearUnusedMemory();
			Cache.runGC();
		});

		FlxG.sound.volumeHandler = (_) ->
		{
			if (volumeTray != null)
				volumeTray.show();
		}

		FlxG.signals.gameResized.add((w, h) ->
		{
			for (tray in trays)
			{
				if (tray != null)
				{
					tray.screenCenter();
				}
			}
		});

		FlxG.console.registerFunction("changeFPS", setFPS);
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

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	#if windows
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "CrashLog_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error + "\nPlease report this error to the sanco#8424";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		DiscordPresence.shutdownPresence();
		new Process(Path.join([Sys.getCwd(), Application.current.meta.get("file") + ".exe"]), ["-crashed:" + e.error]);
		Sys.exit(1);
	}
	#end
}
