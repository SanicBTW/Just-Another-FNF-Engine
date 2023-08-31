package window.debug;

import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.text.TextField;
import openfl.text.TextFormat;
import window.components.RoundedSprite;

// Joins both counters into one place to improve performance )?

@:allow(flixel.FlxGame)
class Overlay extends ExSprite<Overlay>
{
	// Framerate
	public var currentFPS(default, null):Float;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var times:Array<Float>;

	// Memory
	@:noCompletion public static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB'];

	public var currentMem(get, null):Float;
	public var memoryPeak(default, null):Float;

	// Design
	private var _bg:RoundedSprite;
	private var _text:TextField;

	// The corner where the overlay is situated
	public var _cornerPos(default, set):OverlayCorner = TOP_LEFT;

	// Won't change this since I'm too lazy to properly calculate the center
	private var padding:Array<Float> = [20, 15];
	private var offsets:Array<Float> = [0, 0];
	private var fontSize:Int = #if html5 16 #else 14 #end;

	// Lerping
	public var targetX:Float = 0;
	public var targetY:Float = 0;

	public function new(X:Float = 10, Y:Float = 10)
	{
		super();

		targetX = X;
		targetY = Y;

		// Reset FPS variables
		currentFPS = 0;
		cacheCount = 0;
		times = [];

		// Reset memory
		memoryPeak = 0;

		mouseEnabled = false;
	}

	// Setup sprites
	override public function create()
	{
		_text = new TextField();
		_text.text = '0 FPS\n0 MB / 0 MB';
		_text.embedFonts = true;
		_text.selectable = false;
		_text.sharpness = 400;
		_text.defaultTextFormat = new TextFormat(getFont('open_sans.ttf').fontName, fontSize, 0xFFFFFF);
		#if (openfl >= "9.2.0")
		_text.autoSize = LEFT;
		#end

		_bg = new RoundedSprite(x, y, _text.textWidth + padding[0], _text.textHeight + padding[1], [15], FlxColor.BLACK, 0.5);

		addChild(_bg);
		addChild(_text);
	}

	override public function update(elapsed:Float, _)
	{
		var lerpVal:Float = boundTo(1 - (elapsed * 8.6), 0, 1);

		// Resize to fit the text sizes
		_bg.smoothSetSize(_text.textWidth + padding[0], _text.textHeight + padding[1], lerpVal);

		// Move to target positions
		lerpTrack(_bg, "x", targetX + offsets[0], lerpVal);
		lerpTrack(_bg, "y", targetY + offsets[1], lerpVal);

		// Reposition the text based off some shitty formula
		lerpTrack(_text, "x", _bg.x + padding[0] / 4, lerpVal);
		lerpTrack(_text, "y", _bg.y + padding[1] / 4, lerpVal);

		// Workaround for OpenFL versions where auto size doesn't work properly
		#if (openfl < "9.2.0")
		lerpTrack(_text, "width", _bg.width, lerpVal);
		lerpTrack(_text, "height", _bg.height, lerpVal);
		#end

		// Update needed variables
		updateFPS();
		updateMemory();

		// Set the text
		_text.text = '$currentFPS FPS\n${getInterval(currentMem)} / ${getInterval(memoryPeak)}';
	}

	// Update functions
	private function updateFPS()
	{
		var now:Float = haxe.Timer.stamp();
		times.push(now);

		while (times[0] < now - 1)
		{
			times.shift();
		}

		currentFPS = Math.round((times.length + cacheCount) / 2);

		if (currentFPS < FlxG.updateFramerate / 2)
			_text.textColor = 0xFFFF0000;
		else
			_text.textColor = 0xFFFFFFFF;

		cacheCount = times.length;
	}

	private function updateMemory()
	{
		if (currentMem > memoryPeak)
			memoryPeak = currentMem;
	}

	// Forced positions - TODO: Set correct text positions (alignment and shit)
	public function reposition(newWidth:Float, newHeight:Float)
	{
		switch (_cornerPos)
		{
			// We don't use width or height here
			case TOP_LEFT:
				targetX = 10;
				targetY = 10;
				offsets[0] = 0;

			// We don't use width here
			case BOTTOM_LEFT:
				targetX = 10;
				targetY = (newHeight - _bg.height) - 10;
				offsets[0] = 0;

			// We don't use height here
			case TOP_RIGHT:
				targetX = (newWidth - _bg.width) - 10;
				targetY = 10;
				offsets[0] = -20;

			// We use width and height here
			case BOTTOM_RIGHT:
				targetX = (newWidth - _bg.width) - 10;
				targetY = (newHeight - _bg.height) - 10;
				offsets[0] = -20;
		}
	}

	// The same as above but instead updates the position based off the current width and height

	@:noCompletion
	private function set__cornerPos(newCorner:OverlayCorner)
	{
		if (_cornerPos != newCorner)
		{
			_cornerPos = newCorner;
			reposition(FlxG.width, FlxG.height);
		}
		return _cornerPos;
	}

	// Memory helpers
	private static function getInterval(size:Float)
	{
		var data:Int = 0;
		while (size > 1000 && data < intervalArray.length - 1)
		{
			data++;
			size = size / 1000;
		}
		size = Math.round(size * 100) / 100;
		return '$size ${intervalArray[data]}';
	}

	// From OpenFL System, added HL and Android memory getters )?
	// Tested one by one in order to get proper accuracy when getting

	@:noCompletion
	private function get_currentMem()
	{
		#if neko
		// cannot really test this one
		return neko.vm.Gc.stats().heap;
		#elseif hl
		// gets the hl vm gc ig
		// current memory* -> offset -90mb (best option)
		// total allocated -> keeps increasing overtime
		// allocation count -> seems like its the times it has allocated memory)?, increases overtime
		return hl.Gc.stats().currentMemory;
		#elseif cpp
		// should i use cpp.vm.Gc.memInfo(3) - nah thats more innacurate lmao
		// untyped __global__.__hxcpp_gc_used_bytes()
		return cpp.vm.Gc.memInfo64(3);
		#elseif java
		// not tested
		return java.vm.Gc.stats().heap;
		#elseif (js && html5)
		// no other way on getting this one
		return
			untyped #if haxe4 js.Syntax.code #else __js__ #end ("(window.performance && window.performance.memory) ? window.performance.memory.usedJSHeapSize : 0");
		#else
		return 0;
		#end
	}
}

enum OverlayCorner
{
	TOP_LEFT;
	TOP_RIGHT;
	BOTTOM_LEFT;
	BOTTOM_RIGHT;
}
