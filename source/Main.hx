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
import lime.media.openal.ALC;
import lime.media.openal.ALDevice;
#end

class Main extends Sprite
{
	private var gameWidth:Int = 1280;
	private var gameHeight:Int = 720;
	private var initialClass:Class<FlxState> = funkin.states.SongSelection;
	private var zoom:Float = -1;
	private var framerate:Int = getDisplay().currentMode.refreshRate; // VSync :troll: - maybe not now

	public static function main()
	{
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
			// Have to look into this, idk if it closes the device used on the window or sum shit
			var state:Bool = ALC.closeDevice(dev);
			trace(state);
		}
		#end
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

		com.akifox.asynchttp.AsyncHttp.logEnabled = false;
		com.akifox.asynchttp.AsyncHttp.userAgent = network.Request.userAgent;
		FlxGraphic.defaultPersist = true;
		addChild(new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, false, false));

		FlxG.fixedTimestep = false;
		#if !android
		FlxG.mouse.visible = false;
		FlxG.mouse.useSystemCursor = true;
		#end

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(openfl.events.UncaughtErrorEvent.UNCAUGHT_ERROR, (ev) ->
		{
			trace('Uncaught error: ${Std.string(ev.error)}');
			var args:Array<String> = Sys.args();
			args.push('-crash:${Std.string(ev.error)}');
			#if windows
			new sys.io.Process('${backend.io.Path.join(Sys.getCwd(), '${lime.app.Application.current.meta.get("file")}.exe')}', args);
			#end
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
