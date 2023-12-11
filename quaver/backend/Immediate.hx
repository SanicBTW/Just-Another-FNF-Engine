package backend;

using backend.Extensions;

// From https://github.com/ceramic-engine/ceramic/blob/master/runtime/src/ceramic/Immediate.hx
class Immediate
{
	private var _callbacks:Array<Void->Void> = [];
	private var _capacity:Int = 0;
	private var _cbLen:Int = 0;

	public function new() {}

	public function push(handle:Void->Void)
	{
		if (handle == null)
			throw 'Immediate callback shouldn\'t be null!';

		if (_cbLen < _capacity)
		{
			_callbacks.unsafeSet(_cbLen, handle);
			_cbLen++;
		}
		else
		{
			_callbacks[_cbLen++] = handle;
			_capacity++;
		}
	}

	public function flush():Bool
	{
		var didFlush:Bool = false;

		while (_cbLen > 0)
		{
			didFlush = true;

			var pool:ArrayPool = ArrayPool.pool(_cbLen);
			var callbacks:ReusableArray<Any> = pool.get();
			var len:Int = _cbLen;
			_cbLen = 0;

			for (i in 0...len)
			{
				callbacks.set(i, _callbacks.unsafeGet(i));
				_callbacks.unsafeSet(i, null);
			}

			for (i in 0...len)
			{
				var cb:Dynamic = callbacks.get(i);
				cb();
			}

			pool.release(callbacks);
		}

		return didFlush;
	}
}
