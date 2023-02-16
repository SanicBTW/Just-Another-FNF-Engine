package base.system;

// osu!lazer code, all credits to ppy

class Scroll
{
	// The default span of time visible by the length of the scrolling axes.
	private static var TIME_SPAN_DEFAULT(default, null):Float = 1500;

	// The minimum span of time that may be visible by the length of the scrolling axes.
	private static var TIME_SPAN_MIN(default, null):Float = 50;

	// The maximum span of time that may be visible by the length of the scrolling axes.
	private static var TIME_SPAN_MAX(default, null):Float = 20000;

	// The step increase/decrease of the span of time visible by the length of the scrolling axes.
	private static var TIME_SPAN_STEP(default, null):Float = 200;

	private static var DIRECTION(default, null):ScrollDirection = UP;

	private static var TimeRange(default, null):Bindable<Float> = new Bindable(TIME_SPAN_DEFAULT, {
		MinValue: TIME_SPAN_MIN,
		MaxValue: TIME_SPAN_MAX
	});
}

interface IScrollAlgorithm
{
	public function GetDisplayStartTime(originTime:Float, offset:Float, timeRange:Float, scrollLength:Float):Float;
	public function GetLength(startTime:Float, endTime:Float, timeRange:Float, scrollLength:Float):Float;
	public function PositionAt(time:Float, currentTime:Float, timeRange:Float, ?originTime:Float):Float;
	public function TimeAt(position:Float, currentTime:Float, timeRange:Float, scrollLength:Float):Float;
	public function Reset():Void;
}

enum abstract ScrollDirection(Int)
{
	var UP = 1;
	var DOWN = -1;
}
