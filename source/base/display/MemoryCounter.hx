package base.display;

import flixel.FlxG;
import flixel.math.FlxMath;
import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
#if flash
import openfl.Lib;
#end

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class MemoryCounter extends TextField
{
	private static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB'];

	private var memoryPeak(default, null):Float;

	public function new(x:Float = 10, y:Float = 10)
	{
		super();

		this.x = x;
		this.y = y;

		memoryPeak = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 12, 0xFFFFFF);
		text = "Memory: ";

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			__enterFrame(Lib.getTimer() - currentTime);
		});
		#end
	}

	@:noCompletion
	private #if !flash override #end function __enterFrame(_):Void
	{
		if (!visible)
			return;

		var mem:Float = #if cpp cpp.vm.Gc.memInfo64(3) #elseif android java.vm.Gc.stats().heap #else openfl.system.System.totalMemory #end;

		if (mem > memoryPeak)
			memoryPeak = mem;

		text = "Memory: " + getInterval(mem) + "\nMemory peak: " + getInterval(memoryPeak);
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
}
