package backend;

import haxe.Timer;

// From https://github.com/ceramic-engine/ceramic/blob/master/runtime/src/ceramic/ArrayPool.hx
class ArrayPool
{
	private static var ALLOC_STEP = 10;

	/// Factory
	private static var dynPool10:ArrayPool = new ArrayPool(10);

	private static var dynPool100:ArrayPool = new ArrayPool(100);

	private static var dynPool1000:ArrayPool = new ArrayPool(1000);

	private static var dynPool10000:ArrayPool = new ArrayPool(10000);

	private static var dynPool100000:ArrayPool = new ArrayPool(100000);

	private static var didNotifyLargePool:Bool = false;

	public static function pool(size:Int):ArrayPool
	{
		if (size <= 10)
			return cast dynPool10;
		else if (size <= 100)
			return cast dynPool100;
		else if (size <= 1000)
			return cast dynPool1000;
		else if (size <= 10000)
			return cast dynPool10000;
		else if (size <= 100000)
			return cast dynPool100000;
		else
		{
			if (!didNotifyLargePool)
			{
				didNotifyLargePool = true;
				Timer.delay(() ->
				{
					didNotifyLargePool = false;
				}, 2);

				trace('You should avoid asking a pool for arrays with more than 100000 elements (asked: $size) because it needs allocating a temporary one-time pool each time for that.');
			}
			return new ArrayPool(size);
		}
	}

	/// Properties
	private var arrays:ReusableArray<Any> = null;

	private var nextFree:Int = 0;

	private var arrayLengths:Int;

	/// Lifecycle

	public function new(arrayLengths:Int)
	{
		this.arrayLengths = arrayLengths;
	}

	/// Public API

	public function get():ReusableArray<Any>
	{
		if (arrays == null)
			arrays = new ReusableArray(ALLOC_STEP);
		else if (nextFree >= arrays.length)
			arrays.length += ALLOC_STEP;

		var result:ReusableArray<Any> = arrays.get(nextFree);
		if (result == null)
		{
			result = new ReusableArray(arrayLengths);
			arrays.set(nextFree, result);
		}
		@:privateAccess result._poolIndex = nextFree;

		// Compute next free item
		while (true)
		{
			nextFree++;
			if (nextFree == arrays.length)
				break;
			var item:ReusableArray<Any> = arrays.get(nextFree);
			if (item == null)
				break;
			if (@:privateAccess item._poolIndex == -1)
				break;
		}

		return cast result;
	}

	public function release(array:ReusableArray<Any>):Void
	{
		var poolIndex = @:privateAccess array._poolIndex;
		@:privateAccess array._poolIndex = -1;
		if (nextFree > poolIndex)
			nextFree = poolIndex;
		for (i in 0...array.length)
		{
			array.set(i, null);
		}
	}
}
