package backend;

// This is old code so I'm too lazy to rewrite it and shit
class Cursor
{
	private static var cursorOffsets:Map<CursorState, Array<Int>> = [IDLE => [-31, -32], HOVER => [-31, -32]];
	private static var Paths:backend.IsolatedPaths = new backend.IsolatedPaths('cursor');

	public static var curState:CursorState = IDLE;

	public static function setCursor(state:CursorState)
	{
		curState = state;
		flixel.FlxG.mouse.load(Cache.getBitmap(Paths.getPath('cursor$state.png')), 1, cursorOffsets.get(state)[0], cursorOffsets.get(state)[1]);
	}
}

enum abstract CursorState(String) to String
{
	var IDLE = "Idle";
	var HOVER = "Hover";
}
