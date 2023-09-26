package window;

import window.components.*;
import window.packages.*;

// Sorry
enum DesignUpdate
{
	UPDATE_1; // Basic TextFields, basic Volume Tray
	UPDATE_2; // The rounded update, unifying FPS and Memory into a single sprite, also improving the Volume Tray
	UPDATE_3; // Even better design, sliding panels for debugging, graphs and new Volume Panel
}

typedef FPStruct =
{
	public var currentFPS(default, null):Float;
	@:noCompletion var cacheCount:Int;
	@:noCompletion var times:Array<Float>;
	function updateFPS():Void;
}

typedef MemStruct =
{
	@:noCompletion public final intervalArray:Array<String>;
	public var currentMem(get, null):Float;
	public var memoryPeak(default, null):Float;
	function updateMemory():Void;
	@:noCompletion function get_currentMem():Float;
}

typedef VolStruct =
{
	var volume(get, null):Float;
	@:noCompletion function get_volume():Float;
	public function show():Void;
}

// Manages what type of UI Elements, updating and more

@:allow(flixel.FlxGame)
class Overlay extends ExSprite<Overlay>
{
	// Even if fps and memory are unified in Update 2 we want it to be separate although it references the same object
	private var fps:ExSprite<FPStruct>;
	private var memory:ExSprite<MemStruct>;
	// This is not bounded to anything
	private var volume:ExSprite<VolStruct>;

	// X, Y Positions not needed as some stuff is automatically positioned by the overlay
	public function new()
	{
		super();
	}

	// Fired when 'Settings.designUpdate' is changed
	private function reloadDesign()
	{
		switch (Settings.designUpdate)
		{
			case UPDATE_1:
			case UPDATE_2:
				var jCounter:MCounter = new MCounter(10, 8);
				fps = jCounter;
				memory = jCounter;
				addChild(fps);

			case UPDATE_3:
		}
	}
}
