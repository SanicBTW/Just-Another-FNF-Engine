package base;

class Cursor
{
	private static var cursorOffsets:Map<CursorState, Array<Int>> = [IDLE => [-31, -32], HOVER => [-25, -32]];

	public static function setCursor(state:CursorState)
	{
		flixel.FlxG.mouse.load(Paths.image('cursor$state').bitmap, 1, cursorOffsets.get(state)[0], cursorOffsets.get(state)[1]);
	}
}

enum abstract CursorState(String) to String
{
	var IDLE = "Idle";
	var HOVER = "Hover";
}
