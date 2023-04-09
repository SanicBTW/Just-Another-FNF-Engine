package;

import base.ScriptableState;
import base.display.*;
import base.system.*;
import base.system.ui.*;
import flixel.*;
import flixel.graphics.FlxGraphic;
import flixel.system.scaleModes.*;
import lime.app.Application;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import states.RewriteMenu;
#if cpp
import cpp.NativeGc;
#end
#if windows
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
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
	private var framerate:Int = #if !html5 250 #else 60 #end;
	private var skipSplash:Bool = true;
	private var startFullscreen:Bool = false;

	public static var fpsCounter:FramerateCounter;
	public static var memoryCounter:MemoryCounter;
	public static var volumeTray:VolumeTray;
	public static var notifTray:NotificationTray;

	public static var preview:Float = 7.5;

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

		SaveFile.Initialize();
		Controls.init();

		Application.current.window.title = 'BETA ${Application.current.meta.get("version")} - PREVIEW ${preview}';
		DiscordPresence.initPresence();
		FlxGraphic.defaultPersist = true;
		ScriptableState.skipTransIn = true;
		addChild(new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, skipSplash, startFullscreen));

		Lib.current.stage.align = TOP_LEFT;
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		FlxG.scaleMode = new FixedScaleAdjustSizeScaleMode();

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

		notifTray = new NotificationTray();
		addChild(notifTray);

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
			if (notifTray != null)
				notifTray.screenCenter();
		});

		// Is this worse?
		Lib.application.onUpdate.add((_) ->
		{
			if (volumeTray != null && volumeTray.active)
				volumeTray.update();
			if (notifTray != null && notifTray.active)
				notifTray.update();
		});

		FlxG.sound.volumeHandler = function(_)
		{
			if (volumeTray != null)
				volumeTray.show();
		}

		DragDrop.listen();

		#if windows
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		// just listen to the first arg lol
		if (Sys.args()[0].contains("-crashed"))
		{
			notifTray.notify("Well, that sucks", 'Looks like the game crashed\n(${Sys.args()[0].split(":")[1]})');
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
