package window.debug;

import openfl.text.TextField;
import openfl.text.TextFormat;

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
		text = "";
	}

	@:noCompletion
	private override function __enterFrame(_):Void
	{
		if (!visible)
			return;

		var mem:Float = #if cpp cpp.vm.Gc.memInfo64(3) #else openfl.system.System.totalMemory #end;

		if (mem > memoryPeak)
			memoryPeak = mem;

		text = '${getInterval(mem)} / ${getInterval(memoryPeak)}';

		if (mem / 1000000 > 2000)
			textColor = 0xFFFF0000;
		else
			textColor = 0xFFFFFFFF;
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
