package;

import backend.*;
import backend.input.Controls;
import backend.io.CacheFile;
import backend.scripting.ScriptHandler;
import flixel.*;
import flixel.graphics.FlxGraphic;
import lime.system.Display;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;

using StringTools;

#if sys
import lime.media.openal.*;
#end

class Main extends Sprite
{
	private var gameWidth:Int = 1280;
	private var gameHeight:Int = 720;
	private var initialClass:Class<FlxState> = funkin.states.start.TitleState;
	private var zoom:Float = -1;
	private var framerate:Int = getDisplay().currentMode.refreshRate; // VSync :troll: - maybe not now

	public static function main()
	{
		#if android
		if (!android.Permissions.getGrantedPermissions().contains(android.Permissions.WRITE_EXTERNAL_STORAGE)
			&& !android.Permissions.getGrantedPermissions().contains(android.Permissions.READ_EXTERNAL_STORAGE))
		{
			android.Permissions.requestPermission(android.Permissions.WRITE_EXTERNAL_STORAGE);
			android.Permissions.requestPermission(android.Permissions.READ_EXTERNAL_STORAGE);
		}
		#end

		CacheFile.Initialize();
		ScriptHandler.Initialize();
		#if sys
		// My jailbroken chromebook doesn't have an audio driver, i aint payin 10€ for it sorry coolstar
		var dev:Null<ALDevice> = ALC.openDevice();
		if (dev == null)
		{
			trace("Failed to open OpenAL Device");
			Conductor.force = true;
		}
		else
		{
			// Ok this doesn't close the context nor the device used in the OpenAL Window
			var ret:Bool = ALC.closeDevice(dev);
			if (!ret)
				trace("Failed to close OpenAL Device");
		}
		#end
		Lib.current.stage.align = TOP_LEFT;
		Lib.current.stage.scaleMode = NO_SCALE;
		Lib.current.addChild(new Main());
	}

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

		Controls.Initialize();
		IO.Initialize();
		Save.Initialize();

		// Populate on game startup to avoid populating everytime we start a new song
		// Look into it soon
		funkin.Judgement.populate();

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
		#end
		#if html5
		var args:Array<String> = js.Browser.location.search.substring(js.Browser.location.search.indexOf("?") + 1).split("&");
		for (arg in args)
		#end
		{
			arg = arg.toLowerCase();

			Cache.gpuRender = arg.contains("-enable_gpu_rendering");
			Save.shouldLoadQuaver = !arg.contains("-no_quaver_loading");
			#if html5 flixel.FlxState.enableTouch = arg.contains("-enable_touch"); #end

			if (arg.contains("-fps"))
				setFPS(Std.parseInt(arg.split(":")[1]));
		}
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
		addChild(new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, false, false));
		FlxG.plugins.add(new network.AsyncHTTP());

		FlxG.fixedTimestep = false;
		#if !android
		FlxG.mouse.visible = false;
		FlxG.mouse.useSystemCursor = true;
		#end

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(openfl.events.UncaughtErrorEvent.UNCAUGHT_ERROR, (ev) ->
		{
			trace('Uncaught error: ${Std.string(ev.error)}');
			lime.app.Application.current.window.alert(ev.error);
		});
		#end
	}

	// Workaround because my Linux is giving up 0hz on the main display but hdmi is connected
	public static function getDisplay():Display
	{
		var defDisplay:Display = lime.system.System.getDisplay(0);
		for (i in 0...lime.system.System.numDisplays)
		{
			var display:Display = lime.system.System.getDisplay(i);
			if (display.currentMode.refreshRate <= 0)
			{
				@:privateAccess
				display.currentMode.refreshRate = 60;
				defDisplay = display;
			}
		}

		return defDisplay;
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
