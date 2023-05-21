package;

import backend.*;
import flixel.*;
import flixel.graphics.FlxGraphic;
import flixel.system.scaleModes.*;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import window.debug.*;

class Main extends Sprite
{
	private var gameWidth:Int = 1280;
	private var gameHeight:Int = 720;
	private var initialClass:Class<FlxState> = funkin.states.SongSelection;
	private var zoom:Float = -1;
	private var framerate:Int = #if native 250 #else 60 #end;

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
		setupGame();

		FlxG.signals.preStateCreate.add((state:FlxState) ->
		{
			Cache.clearStoredMemory();
			FlxG.bitmap.dumpCache();
			Cache.collect();
		});

		FlxG.signals.preStateSwitch.add(() ->
		{
			Cache.clearUnusedMemory();
			Cache.collect();
		});

		Lib.application.onExit.add((_) ->
		{
			IO.cleanTemp();
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

		// FlxGraphic.defaultPersist = true;
		addChild(new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, true, false));

		FlxG.scaleMode = new FixedScaleAdjustSizeScaleMode();
		FlxG.fixedTimestep = false;
		#if !android
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		FlxG.mouse.useSystemCursor = true;
		#end
	}
}
