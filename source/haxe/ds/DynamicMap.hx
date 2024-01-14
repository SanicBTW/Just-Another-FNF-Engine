package haxe.ds;

import haxe.Constraints.IMap;
import haxe.ds.EnumValueMap;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;

// dumb map i quickly cooked for straightforward access to stored map values making a map act as a dynamic
// for ex: map.key = value; trace(map.key) returns the saved value without having to use any map methods (get, set)

/**
	Map allows key to value mapping for arbitrary value types, and many key
	types.

	This is a multi-type abstract, it is instantiated as one of its
	specialization types depending on its type parameters.

	A Map can be instantiated without explicit type parameters. Type inference
	will then determine the type parameters from the usage.

	Maps can also be created with `[key1 => value1, key2 => value2]` syntax.

	Map is an abstract type, it is not available at runtime.

	This type of Map allows you to access its values as an array and as map.key
	without using any Map built-in methods.

	Also includes length.

	@see https://haxe.org/manual/std-Map.html
**/
@:transitive
@:multiType(@:followWithAbstracts K)
abstract DynamicMap<K, V>(IMap<K, V>)
{
	/**
		Creates a new Map.

		This becomes a constructor call to one of the specialization types in
		the output. The rules for that are as follows:

		1. if `K` is a `String`, `haxe.ds.StringMap` is used
		2. if `K` is an `Int`, `haxe.ds.IntMap` is used
		3. if `K` is an `EnumValue`, `haxe.ds.EnumValueMap` is used
		4. if `K` is any other class or structure, `haxe.ds.ObjectMap` is used
		5. if `K` is any other type, it causes a compile-time error

		(Cpp) Map does not use weak keys on `ObjectMap` by default.
	**/
	public function new();

	/**
		Maps `key` to `value`.

		If `key` already has a mapping, the previous value disappears.

		If `key` is `null`, the result is unspecified.
	**/
	@:op([])
	public inline function set(key:K, value:V)
		this.set(key, value);

	// Direct access (forced to use string for obvious reasons)

	@:op(a.b) @:noCompletion
	private inline function dSet(key:String, value:V)
		this.set(cast key, value);

	/**
		Returns the current mapping of `key`.

		If no such mapping exists, `null` is returned.

		Note that a check like `map.get(key) == null` can hold for two reasons:

		1. the map has no mapping for `key`
		2. the map has a mapping with a value of `null`

		If it is important to distinguish these cases, `exists()` should be
		used.

		If `key` is `null`, the result is unspecified.
	**/
	@:op([])
	public inline function get(key:K)
		return this.get(key);

	// Direct access (forced to use string for obvious reasons)

	@:op(a.b) @:noCompletion
	private inline function dGet(key:String)
		return this.get(cast key);

	/**
		Returns true if `key` has a mapping, false otherwise.

		If `key` is `null`, the result is unspecified.
	**/
	public inline function exists(key:K)
		return this.exists(key);

	/**
		Removes the mapping of `key` and returns true if such a mapping existed,
		false otherwise.

		If `key` is `null`, the result is unspecified.
	**/
	public inline function remove(key:K)
		return this.remove(key);

	/**
		Returns an Iterator over the keys of `this` Map.

		The order of keys is undefined.
	**/
	public inline function keys():Iterator<K>
	{
		return this.keys();
	}

	/**
		Returns an Iterator over the values of `this` Map.

		The order of values is undefined.
	**/
	public inline function iterator():Iterator<V>
	{
		return this.iterator();
	}

	/**
		Returns an Iterator over the keys and values of `this` Map.

		The order of values is undefined.
	**/
	public inline function keyValueIterator():KeyValueIterator<K, V>
	{
		return this.keyValueIterator();
	}

	/**
		Returns a shallow copy of `this` map.

		The order of values is undefined.
	**/
	public inline function copy():Map<K, V>
	{
		return cast this.copy();
	}

	/**
		Returns a String representation of `this` Map.

		The exact representation depends on the platform and key-type.
	**/
	public inline function toString():String
	{
		return this.toString();
	}

	/**
		Removes all keys from `this` Map.
	**/
	public inline function clear():Void
	{
		this.clear();
	}

	/**
		Makes a loop and counts every value from `this` map
	**/
	public inline function length():Int
	{
		var length:Int = 0;

		for (i in this)
		{
			length++;
		}

		return length;
	}

	@:to static inline function toStringMap<K:String, V>(t:IMap<K, V>):StringMap<V>
	{
		return new StringMap<V>();
	}

	@:to static inline function toIntMap<K:Int, V>(t:IMap<K, V>):IntMap<V>
	{
		return new IntMap<V>();
	}

	@:to static inline function toEnumValueMapMap<K:EnumValue, V>(t:IMap<K, V>):EnumValueMap<K, V>
	{
		return new EnumValueMap<K, V>();
	}

	@:to static inline function toObjectMap<K:{}, V>(t:IMap<K, V>):ObjectMap<K, V>
	{
		return new ObjectMap<K, V>();
	}

	@:from static inline function fromStringMap<V>(map:StringMap<V>):DynamicMap<String, V>
	{
		return cast map;
	}

	@:from static inline function fromIntMap<V>(map:IntMap<V>):DynamicMap<Int, V>
	{
		return cast map;
	}

	@:from static inline function fromObjectMap<K:{}, V>(map:ObjectMap<K, V>):DynamicMap<K, V>
	{
		return cast map;
	}
}
