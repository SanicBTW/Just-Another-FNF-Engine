package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.system.FlxSound;
import flixel.util.FlxDestroyUtil;
import flixel.util.typeLimit.OneOfTwo;
import haxe.io.Path;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.Assets;

using StringTools;

#if cpp
import cpp.vm.Gc;
#elseif android
import java.vm.Gc;
#end

// https://github.com/Stilic/FNF-FlatyEngine/blob/main/source/Cache.hx
// Rewritten completely and using some FlatyEngine code
// This manages local assets (game folder assets) and will only store external assets through another class that will be called in Paths
// Holy shit it actually improved performance a lot holy shit
class Cache
{
	// Keyed assets / Cache store - joined all of the tracked arrays from before to one to avoid having an array for each one
	public static var keyedAssets:Map<String, Dynamic> = [];

	// Persistent assets / assets that won't get cleaned hopefully
	private static var persistentAssets:Array<String> = [
		'assets/music/freakyMenu.ogg',
		'assets/music/tea-time.ogg',
		'fonts:assets/fonts/VCR/VCR.png',
		'fonts:assets/fonts/Funkin/Funkin.png'
	];

	// Casting is unnecessary as it gets casted to the return type of the function
	public static function getBitmapData(id:String, ?bitmap:BitmapData):Null<BitmapData>
	{
		if (isCached(id))
			return keyedAssets.get(id);

		if (!exists(id) && bitmap == null)
		{
			log('$id not found, returning null', 'bitmap data getter');
			return null;
		}

		if (exists(id) && bitmap == null)
			bitmap = Assets.getBitmapData(id);

		keyedAssets.set(id, bitmap);

		// Return bitmap on first call
		return bitmap;
	}

	public static function getGraphic(id:String):Null<FlxGraphic>
	{
		if (isCached(id))
			return keyedAssets.get(id);

		if (!exists(id))
		{
			log('$id not found, returning null', 'flxgraphic getter');
			return null;
		}

		var newBitmap:BitmapData = getBitmapData(id);
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, id);
		keyedAssets.set(id, newGraphic);

		// Return graphic on first call
		return newGraphic;
	}

	public static function getSound(id:String):Null<Sound>
	{
		if (isCached(id))
			return keyedAssets.get(id);

		if (!exists(id))
		{
			log('$id not found, returning null', 'sound getter');
			return null;
		}

		var sound:Sound = Assets.getSound(id);
		keyedAssets.set(id, sound);

		// Return sound on first call
		return sound;
	}

	public static function getAtlas(id:String, type:AtlasType):Null<Dynamic>
	{
		if (isCached(id))
			return keyedAssets.get(id).atlas;

		var path:String = id;
		if (!path.endsWith(".png"))
			path += ".png";

		var graphic:FlxGraphic = getGraphic(path);
		if (graphic == null)
		{
			log('$id returned null on graphic', 'atlas getter');
			return null;
		}
		path = path.substring(0, path.length - 4);

		var newAtlas:Atlas = {atlas: null, type: type};
		switch (type)
		{
			case Sparrow:
				{
					path += ".xml";
					newAtlas.atlas = FlxAtlasFrames.fromSparrow(graphic, path);
				}
			case Packer:
				{
					path += ".txt";
					newAtlas.atlas = FlxAtlasFrames.fromSpriteSheetPacker(graphic, path);
				}
			case BMFont:
				{
					path += ".xml";
					newAtlas.atlas = FlxBitmapFont.fromAngelCode(graphic, path);
				}
		}

		if (newAtlas.atlas == null)
		{
			log('$id atlas returned null', "atlas getter");
			return null;
		}

		keyedAssets.set(id, newAtlas);

		// Return atlas on first call
		return newAtlas.atlas;
	}

	// Cleaning functions - returns a bool indicating that it has been cleaned successfully

	public static function removeGraphic(id:String):Bool
	{
		var graphic:Null<FlxGraphic> = keyedAssets.get(id);
		@:privateAccess
		if (graphic != null)
		{
			removeAtlas(id);
			FlxG.bitmap._cache.remove(id);
			graphic.destroy();
			graphic = null;
			keyedAssets.remove(id);
			return true;
		}
		return false;
	}

	public static function removeAtlas(id:String):Bool
	{
		var atlas:Null<Atlas> = keyedAssets.get(id);
		@:privateAccess
		if (atlas != null)
		{
			FlxDestroyUtil.destroy(atlas.atlas);
			keyedAssets.remove(id);
			return true;
		}
		return false;
	}

	public static function removeSound(id:String):Bool
	{
		var obj:Null<Sound> = keyedAssets.get(id);
		if (obj != null)
		{
			#if !html5
			obj.close();
			obj = null;
			#end
			Assets.cache.removeSound(id);
			keyedAssets.remove(id);
			return true;
		}
		return false;
	}

	// Maybe I should use this instead of the other one dunno
	public static function destroyGraphic(graphic:FlxGraphic)
	{
		if (graphic != null && graphic.bitmap != null)
		{
			graphic.bitmap.lock();

			@:privateAccess
			if (graphic.bitmap.__texture != null)
			{
				graphic.bitmap.__texture.dispose();
				graphic.bitmap.__texture = null;
			}
			graphic.bitmap.disposeImage();
			FlxG.bitmap.remove(graphic);
		}
	}

	public static function clearUnusedMemory()
	{
		for (key in keyedAssets.keys())
		{
			var obj:Null<Dynamic> = keyedAssets.get(key);
			if (obj is FlxGraphic)
			{
				var graphic = cast(obj, FlxGraphic);
				if (graphic.useCount <= 0 && !persistentAssets.contains(key))
					removeGraphic(key);
			}
		}

		clearUnusedSounds();

		runGC();
	}

	public static function clearStoredMemory()
	{
		for (key in keyedAssets.keys())
		{
			if (!persistentAssets.contains(key))
				removeGraphic(key);
		}

		@:privateAccess
		for (graphic in FlxG.bitmap._cache)
		{
			if (!persistentAssets.contains(graphic.key) && !keyedAssets.exists(graphic.key))
				destroyGraphic(graphic);
		}

		clearUnusedSounds();

		runGC();
	}

	public static function clearUnusedSounds()
	{
		var usedSounds:Array<Sound> = [];

		FlxG.sound.list.forEachAlive((sound:FlxSound) ->
		{
			@:privateAccess
			if (sound._sound != null && !usedSounds.contains(sound._sound))
				usedSounds.push(sound._sound);
		});

		@:privateAccess
		if (FlxG.sound.music != null && FlxG.sound.music._sound != null && !usedSounds.contains(FlxG.sound.music._sound))
			usedSounds.push(FlxG.sound.music._sound);

		// it will prob get all of the types and will get casted into a sound type lol
		for (key in keyedAssets.keys())
		{
			var sound:Null<Sound> = keyedAssets.get(key);
			if (!usedSounds.contains(sound) && !persistentAssets.contains(key))
				removeSound(key);
		}
	}

	public static function runGC()
	{
		#if cpp
		Gc.compact();
		Gc.run(true);
		#elseif android
		Gc.run();
		#end
	}

	// Helper functions

	public static inline function isCached(id:String):Bool
		return keyedAssets.exists(id);

	public static inline function exists(id:String):Bool
		return Assets.exists(id);

	// dumb ass function lol
	public static inline function log(message:String, from:String)
		return trace('$message - $from');
}

enum AtlasType
{
	Sparrow;
	Packer;
	BMFont;
}

typedef Atlas =
{
	var atlas:OneOfTwo<FlxAtlasFrames, FlxBitmapFont>;
	var type:AtlasType;
}
/* soon
	// Class to store the type of the asset for cleaning
	class CacheKey<T>
	{

}*/
