package window.debug;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;

class MemoryCounter extends OFLSprite
{
	private static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB'];

	private var currentMem(get, null):Float;
	private var memoryPeak(default, null):Float;

	private var bg:Shape;
	private var memText:TextField;
	private var offsetWidth:Float = 6;

	// lerping haha
	public var targetX:Float = 0;
	public var targetY:Float = 0;

	public function new(X:Float = 10, Y:Float = 10)
	{
		super();

		targetX = X;
		targetY = Y;

		memoryPeak = 0;
		mouseEnabled = false;
	}

	override public function create()
	{
		memText = new TextField();
		memText.text = '0 MB / 0 MB';
		memText.embedFonts = true;
		memText.defaultTextFormat = new TextFormat(getFont('open_sans.ttf').fontName, 12, 0xFFFFFF);
		memText.selectable = false;
		memText.autoSize = LEFT;

		bg = drawRound(x, y, memText.textWidth + offsetWidth, memText.textHeight + 5, [5], FlxColor.BLACK, 0.5);

		addChild(bg);
		addChild(memText);
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = boundTo(1 - (elapsed * 8.6), 0, 1);

		// da bg
		lerpTrack(bg, "width", memText.textWidth + offsetWidth, lerpVal);
		lerpTrack(bg, "x", targetX, lerpVal);
		lerpTrack(bg, "y", targetY, lerpVal);

		// funky text
		lerpTrack(memText, "x", bg.x, lerpVal);
		lerpTrack(memText, "y", bg.y, lerpVal);
		updateMemText();
	}

	private function updateMemText()
	{
		if (currentMem > memoryPeak)
			memoryPeak = currentMem;

		memText.text = '${getInterval(currentMem)} / ${getInterval(memoryPeak)}';
	}

	private static function getInterval(size:Float)
	{
		var data:Int = 0;
		while (size > 1024 && data < intervalArray.length - 1)
		{
			data++;
			size = size / 1024;
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
		return untyped __global__.__hxcpp_gc_used_bytes();
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
