package base.system;

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
}

enum abstract ScrollDirection(Int)
{
	var UP = 1;
	var DOWN = -1;
}
