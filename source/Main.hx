package;

import backend.*;
import flixel.*;
import flixel.graphics.FlxGraphic;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;

using StringTools;

class Main extends Sprite
{
	private var gameWidth:Int = 1280;
	private var gameHeight:Int = 720;
	private var initialClass:Class<FlxState> = funkin.states.SongSelection;
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

		// Dynamic init omg
		Type.getClassName(Save); // I need to do this to avoid crashing, dunno why maybe the class isn't loaded into the global scope
		for (classInit in ["IO", "Save", "Controls", "DiscordPresence", "ScriptHandler"])
		{
			trace('Initializing $classInit');
			var targetClass = Type.resolveClass('backend.$classInit');
			Reflect.callMethod(targetClass, Reflect.field(targetClass, "Initialize"), []);
		}

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

		FlxG.fixedTimestep = false;
		#if !android
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		FlxG.mouse.useSystemCursor = true;
		#end

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(openfl.events.UncaughtErrorEvent.UNCAUGHT_ERROR, (ev) ->
		{
			trace('Uncaught error: ${Std.string(ev.error)}');
			#if sys
			var args:Array<String> = Sys.args();
			args.push('-crash:${Std.string(ev.error)}');
			new sys.io.Process('${haxe.io.Path.join([Sys.getCwd(), '${lime.app.Application.current.meta.get("file")}.exe'])}', args);
			#end
		});
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
