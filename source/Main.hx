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
	private var initialClass:Class<FlxState> = funkin.states.SongSelection;
	private var zoom:Float = -1;
	private var framerate:Int = 250;

	public static function main()
		Lib.current.addChild(new Main());

	public function new()
	{
		super();

		for (arg in Sys.args())
		{
			if (arg.contains("-enable_gpu_rendering"))
				Cache.gpuRender = true;

			if (arg.contains("-fps"))
				setFPS(Std.parseInt(arg.split(":")[1]));
		}

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
		#if FS_ACCESS IO.Initialize(); #end
		ScriptHandler.Initialize();
		Async.Initialize();
		setupGame();

		FlxG.signals.preStateCreate.add((_) ->
		{
			Cache.clearStoredMemory();
			Cache.clearUnusedMemory();
			FlxG.bitmap.dumpCache();
			Cache.collect();
		});
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

		// vsync shit right here bois framerate = lime.system.System.getDisplay(0).currentMode.refreshRate;

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
