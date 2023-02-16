package base;

class Bindable<T>
{
	private var value:T;
	private var minValue:T;
	private var maxValue:T;

	public function new(Value:T, _:{MinValue:T, MaxValue:T})
	{
		value = Value;
		minValue = _.MinValue;
		maxValue = _.MaxValue;
	}

	public function get():Float
		return Math.max(cast(minValue, Float), Math.min(cast(maxValue, Float), cast(value, Float)));

	public static inline function classicBound(value:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, value));
}
