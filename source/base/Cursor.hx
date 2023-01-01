package base;

class Cursor
{
	private static var cursorOffsets:Map<CursorState, Array<Int>> = [IDLE => [-31, -32], HOVER => [-25, -32]];
	public static var currentState(default, set):CursorState;

	private static function set_currentState(newState:CursorState):CursorState
	{
		if (currentState != newState)
		{
			flixel.FlxG.mouse.load(Paths.image('cursor$newState').bitmap, 1, cursorOffsets.get(newState)[0], cursorOffsets.get(newState)[1]);
			currentState = newState;
		}
		return newState;
	}
}

enum abstract CursorState(String) to String
{
	var IDLE = "Idle";
	var HOVER = "Hover";
}
