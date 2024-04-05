package backend;

// From https://github.com/ceramic-engine/ceramic/blob/master/runtime/src/ceramic/Extensions.hx#L10
class Extensions<T>
{
	public static inline function unsafeGet<T>(array:Array<T>, index:Int):T
	{
		if (index < 0 || index >= array.length)
			throw 'Invalid unsafeGet: index=$index length=${array.length}';
		#if cpp
		return untyped array.__unsafe_get(index);
		#elseif cs
		return cast untyped __cs__('{0}.__a[{1}]', array, index);
		#else
		return array[index];
		#end
	}

	public static inline function unsafeSet<T>(array:Array<T>, index:Int, value:T):Void
	{
		if (index < 0 || index >= array.length)
			throw 'Invalid unsafeSet: index=$index length=${array.length}';
		#if cpp
		untyped array.__unsafe_set(index, value);
		#elseif cs
		return cast untyped __cs__('{0}.__a[{1}] = {2}', array, index, value);
		#else
		array[index] = value;
		#end
	}

	public static inline function setArrayLength<T>(array:Array<T>, length:Int):Void
	{
		if (array.length != length)
		{
			#if cpp
			untyped array.__SetSize(length);
			#else
			if (array.length > length)
			{
				array.splice(length, array.length - length);
			}
			else
			{
				var dArray:Array<Dynamic> = array;
				while (dArray.length < length)
					dArray.push(null);
			}
			#end
		}
	}

	/**
	 * Return a random element contained in the given array
	 */
	public static inline function randomElement<T>(array:Array<T>):T
	{
		return array[Math.floor(Math.random() * 0.99999 * array.length)];
	}

	/**
	 * Return a random element contained in the given array that is not equal to the `except` arg.
	 * @param array  The array in which we extract the element from
	 * @param except The element we don't want
	 * @param unsafe If set to `true`, will prevent allocating a new array (and may be faster) but will loop forever if there is no element except the one we don't want
	 * @return The random element or `null` if nothing was found
	 */
	public static function randomElementExcept<T>(array:Array<T>, except:T, unsafe:Bool = false):T
	{
		if (unsafe)
		{
			// Unsafe
			var ret = null;

			do
			{
				ret = randomElement(array);
			}
			while (ret == except);

			return ret;
		}
		else
		{
			// Safe

			// Work on a copy
			var array_:Array<T> = [];
			for (item in array)
			{
				array_.push(item);
			}

			// Shuffle array
			shuffle(array_);

			// Get first item different than `except`
			for (item in array_)
			{
				if (item != except)
					return item;
			}
		}

		return null;
	}

	/**
	 * Return a random element contained in the given array that is validated by the provided validator.
	 * If no item is valid, returns null.
	 * @param array  The array in which we extract the element from
	 * @param validator A function that returns true if the item is valid, false if not
	 * @return The random element or `null` if nothing was found
	 */
	public static function randomElementMatchingValidator<T>(array:Array<T>, validator:T->Bool):T
	{
		// Work on a copy
		var array_:Array<T> = [];
		for (item in array)
		{
			array_.push(item);
		}

		// Shuffle array
		shuffle(array_);

		// Get first item different than `except`
		for (item in array_)
		{
			if (validator(item))
				return item;
		}

		return null;
	}

	/**
	 * Shuffle an Array. This operation affects the array in place.
	 * The shuffle algorithm used is a variation of the [Fisher Yates Shuffle](http://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)
	 */
	public static function shuffle<T>(arr:Array<T>):Void
	{
		inline function random(from:Int, to:Int):Int
		{
			return from + Math.floor(((to - from + 1) * Math.random()));
		}

		if (arr != null)
		{
			for (i in 0...arr.length)
			{
				var j = random(0, arr.length - 1);
				var a = arr[i];
				var b = arr[j];
				arr[i] = b;
				arr[j] = a;
			}
		}
	}

	public static function swapElements<T>(arr:Array<T>, index0:Int, index1:Int):Void
	{
		var a = arr[index0];
		arr[index0] = arr[index1];
		arr[index1] = a;
	}

	public static function removeNullElements<T>(arr:Array<T>):Void
	{
		var i = 0;
		var gap = 0;
		var len = arr.length;
		while (i < len)
		{
			do
			{
				var item = unsafeGet(arr, i);
				if (item == null)
				{
					i++;
					gap++;
				}
				else
				{
					break;
				}
			}
			while (i < len);

			if (gap != 0 && i < len)
			{
				var key = i - gap;
				unsafeSet(arr, key, unsafeGet(arr, i));
			}

			i++;
		}

		setArrayLength(arr, len - gap);
	}

	public static function findFirst<T>(arr:Array<T>, f:T->Bool):T
	{
		var resolve:T = null;

		for (v in arr)
		{
			if (f(v))
			{
				resolve = v;
				break;
			}
		}

		return resolve;
	}

	// Check AudioBuffer "loadFromFile" function
	public static function loadFromBytes(bytes:haxe.io.Bytes):SPromise<lime.media.AudioBuffer>
	{
		return new SPromise<lime.media.AudioBuffer>((resolve, reject) -> {
			#if (js && html5 && lime_howlerjs)
			var audioBuffer:lime.media.AudioBuffer = new lime.media.AudioBuffer();

			@:privateAccess
			{
				audioBuffer.src = new lime.media.howlerjs.Howl({
					src: [
						"data:" + lime.media.AudioBuffer.__getCodec(bytes) + ";base64," + haxe.crypto.Base64.encode(bytes)
					],
					preload: false
				});

				audioBuffer.__srcHowl.on("load", () ->
				{
					resolve(audioBuffer);
				});

				audioBuffer.__srcHowl.on("loaderror", (id, msg) ->
				{
					reject(msg);
				});

				audioBuffer.__srcHowl.load();
			}
			#else
			resolve(lime.media.AudioBuffer.fromBytes(bytes));
			#end
		});
	}
}
