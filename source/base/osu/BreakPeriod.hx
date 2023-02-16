package base.osu;

class BreakPeriod
{
	public var MIN_BREAK_DURATION(default, null):Float = 650;

	public var StartTime:Float;
	public var EndTime:Float;
	public var Duration(get, default):Float;

	private function get_Duration():Float
		return EndTime - StartTime;

	public var HasEffect(get, default):Bool;

	private function get_HasEffect():Bool
		return Duration >= MIN_BREAK_DURATION;

	public function new(startTime:Float, endTime:Float)
	{
		StartTime = startTime;
		EndTime = endTime;
	}

	public function Contains(time:Float):Bool
		return time >= StartTime && time <= EndTime - MIN_BREAK_DURATION / 2;
}
