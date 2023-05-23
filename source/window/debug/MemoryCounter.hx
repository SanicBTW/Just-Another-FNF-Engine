package window.debug;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;

@:allow(flixel.FlxGame)
class MemoryCounter extends OFLSprite
{
	private static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB'];

	private var currentMem(get, null):Float;
	private var memoryPeak(default, null):Float;

	private var bg:Shape;
	private var memText:TextField;

	private var padding:Array<Float> = [15, 15];

	private var fontSize:Int = 16;

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
		memText.defaultTextFormat = new TextFormat(getFont('open_sans.ttf').fontName, fontSize, 0xFFFFFF);
		memText.selectable = false;
		memText.autoSize = LEFT;

		bg = drawRound(x, y, memText.textWidth + padding[0], memText.textHeight + padding[1], [10], FlxColor.BLACK, 0.5);

		addChild(bg);
		addChild(memText);
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = boundTo(1 - (elapsed * 8.6), 0, 1);

		// them bg sizes
		lerpTrack(bg, "width", memText.textWidth + padding[0], lerpVal);
		lerpTrack(bg, "height", memText.textHeight + padding[1], lerpVal);

		// them bg pos
		lerpTrack(bg, "x", targetX, lerpVal);
		lerpTrack(bg, "y", targetY, lerpVal);

		// text pos based off bg pos and some shitty center calculation
		// its actually only good with 15 padding bruh
		lerpTrack(memText, "x", bg.x + ((bg.width - memText.textWidth) / 2) - padding[0] / 4, lerpVal);
		lerpTrack(memText, "y", bg.y + ((bg.height - memText.textHeight) / 2) - padding[1] / 4, lerpVal);
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
		// should i use cpp.vm.Gc.memInfo(3)
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
