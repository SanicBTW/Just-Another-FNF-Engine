package backend;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.Assets;

using StringTools;

#if cpp
import cpp.vm.Gc;
#elseif android
import java.vm.Gc;
#end

// Once again rewritten
// Mix between Flaty Engine, Forever Engine Rewrite and some cleaner code
class Cache
{
	// Cached assets
	public static var keyedAssets:Map<String, Dynamic> = [];

	// Non-cleanable assets
	private static var persistentAssets:Array<String> = [];

	public static function set<T>(asset:T, ?key:String):T
	{
		if (key != null)
		{
			if (isCached(key) || asset == null)
				return keyedAssets.get(key);

			if (asset != null)
				keyedAssets.set(key, asset);
		}

		if (key == null)
		{
			key = Random.uniqueId().split("-")[0];
		}
		trace(key);

		return asset;
	}

	public static function get(key:String):Dynamic
	{
		if (isCached(key))
			return keyedAssets.get(key);

		return null;
	}

	// Helper functions

	public static function collect()
	{
		#if cpp
		Gc.compact();
		Gc.run(true);
		#elseif android
		Gc.run();
		#end
	}

	public static inline function isCached(id:String):Bool
		return keyedAssets.exists(id);

	public static inline function exists(id:String):Bool
		return Assets.exists(id);
}
