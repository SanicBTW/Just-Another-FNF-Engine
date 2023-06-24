package;

import backend.*;
import flixel.*;
import flixel.graphics.FlxGraphic;
import flixel.system.scaleModes.FixedScaleAdjustSizeScaleMode;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import window.VolumePanel;

class Main extends Sprite
{
	private var gameWidth:Int = 1366;
	private var gameHeight:Int = 768;
	private var initialClass:Class<FlxState> = states.ScrollTest;
	private var zoom:Float = -1;
	private var framerate:Int = lime.system.System.getDisplay(0).currentMode.refreshRate;

	public static var cock:VolumePanel;

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

		Controls.Init();
		// ScriptHandler.Initialize();
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

		FlxGraphic.defaultPersist = true;
		addChild(new FlxGame(gameWidth, gameHeight, initialClass, zoom, framerate, framerate, true, false));

		cock = new VolumePanel();
		addChild(cock);

		FlxG.scaleMode = new FixedScaleAdjustSizeScaleMode();
		FlxG.fixedTimestep = false;
		#if !android
		FlxG.autoPause = false;
		FlxG.mouse.visible = true;
		FlxG.mouse.useSystemCursor = true;
		#end
	}
}
