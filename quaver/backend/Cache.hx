package backend;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxSound;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;
import openfl.utils.Assets;

using StringTools;

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif android
import java.vm.Gc;
#end

// Once again rewritten
// Mix between Flaty Engine, Forever Engine Rewrite and some cleaner code
class Cache
{
	// Cached assets
	private static var keyedBitmaps:Map<String, BitmapData> = [];
	private static var keyedGraphics:Map<String, FlxGraphic> = [];
	private static var keyedAtlases:Map<String, CachedAtlas> = [];
	private static var keyedSounds:Map<String, Sound> = [];

	// Non-cleanable assets
	private static var persistentAssets:Array<String> = [];

	// Use GPU to render textures
	public static var gpuRender:Bool = true;

	// Generic stuff hurts my brain, so imma try to do the least with it
	// Dynamic set
	public static function set<T>(asset:T, map:CacheMap, key:String):T
	{
		trace('Setting new asset $key');

		if (isCached(key, map) || asset == null)
			return cast(Reflect.field(Cache, 'keyed${map}'), Map<String, Dynamic>).get(key);

		if (asset != null)
			cast(Reflect.field(Cache, 'keyed${map}'), Map<String, Dynamic>).set(key, asset);

		return asset;
	}

	// Basic get
	public static function get(key:String, map:CacheMap):Dynamic
	{
		if (isCached(key, map))
			return cast(Reflect.field(Cache, 'keyed${map}'), Map<String, Dynamic>).get(key);

		return null;
	}

	// Them getters
	public static function getBitmap(id:String):Null<BitmapData>
	{
		if (isCached(id, BITMAP))
			return keyedBitmaps.get(id);

		if (!exists(id) && !fromFS(id))
		{
			trace('$id not found, returning null');
			return null;
		}

		var bitmap:BitmapData = (fromFS(id)) ? BitmapData.fromFile(id) : Assets.getBitmapData(id);

		if (gpuRender)
		{
			bitmap.lock();

			var texture:Texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, RGBA_HALF_FLOAT, true, 0);
			texture.uploadFromBitmapData(bitmap);

			bitmap.disposeImage();
			FlxDestroyUtil.dispose(bitmap);
			bitmap = BitmapData.fromTexture(texture);
		}

		keyedBitmaps.set(id, bitmap);

		// Return bitmap on first call
		return bitmap;
	}

	public static function getGraphic(id:String):Null<FlxGraphic>
	{
		if (isCached(id, GRAPHIC))
			return keyedGraphics.get(id);

		if (!exists(id) && !fromFS(id))
		{
			trace('$id not found, returning null');
			return null;
		}

		var bitmap:BitmapData = getBitmap(id);
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, id);

		keyedGraphics.set(id, newGraphic);

		// Return graphic on first call
		return newGraphic;
	}

	public static inline function getText(path:String):String
	{
		return #if FS_ACCESS (fromFS(path)) ? sys.io.File.getContent(path) : #end
		Assets.getText(path);
	}

	public static inline function getFont(key:String)
		return 'assets/fonts/$key';

	public static function getAtlas(id:String, type:AtlasType):Null<FlxAtlasFrames>
	{
		if (isCached(id, ATLAS))
			return keyedAtlases.get(id).frames;

		var path:String = id;
		if (!path.endsWith('.png'))
			path += ".png";

		var frames:FlxAtlasFrames = null;

		var graphic:FlxGraphic = getGraphic(path);
		path = path.substring(0, path.length - 4);

		switch (type)
		{
			case Sparrow:
				path += ".xml";
				var text:String = getText(path);
				frames = FlxAtlasFrames.fromSparrow(graphic, text);
			case Packer:
				path += ".txt";
				var text:String = getText(path);
				frames = FlxAtlasFrames.fromSpriteSheetPacker(graphic, text);
		}

		if (frames != null)
		{
			keyedAtlases.set(id, {frames: frames, type: type});
			return frames;
		}

		return frames;
	}

	public static function getSound(id:String):Null<Sound>
	{
		if (isCached(id, SOUND))
			return keyedSounds.get(id);

		if (!exists(id) && !fromFS(id))
		{
			trace('$id not found, returning null');
			return null;
		}

		var sound:Sound = (fromFS(id)) ? Sound.fromFile(id) : Assets.getSound(id);
		keyedSounds.set(id, sound);

		// Return sound on first call
		return sound;
	}

	// Cleaning functions - Returns a bool indicating that it has been cleaned successfully
	public static function removeBitmapData(id:String):Bool
	{
		var bitmap:Null<BitmapData> = keyedBitmaps.get(id);
		if (bitmap != null)
		{
			Assets.cache.removeBitmapData(id);
			bitmap.dispose();
			bitmap = null;
			keyedBitmaps.remove(id);
			return true;
		}
		return false;
	}

	public static function removeGraphic(id:String):Bool
	{
		var graphic:Null<FlxGraphic> = keyedGraphics.get(id);
		@:privateAccess
		if (graphic != null)
		{
			removeAtlas(id);
			removeBitmapData(id);
			FlxG.bitmap._cache.remove(id);
			graphic.destroy();
			keyedGraphics.remove(id);
			return true;
		}
		return false;
	}

	public static function removeAtlas(id:String):Bool
	{
		id = id.substring(0, id.length - 4);

		var atlas:Null<CachedAtlas> = keyedAtlases.get(id);
		if (atlas != null)
		{
			atlas.frames = FlxDestroyUtil.destroy(atlas.frames);
			keyedAtlases.remove(id);
			return true;
		}
		return false;
	}

	public static function removeSound(id:String):Bool
	{
		var obj:Null<Sound> = keyedSounds.get(id);
		if (obj != null)
		{
			#if !html5
			obj.close();
			obj = null;
			#end
			Assets.cache.removeSound(id);
			keyedSounds.remove(id);
			return true;
		}
		return false;
	}

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
			graphic.bitmap.dispose();
			FlxG.bitmap.remove(graphic);
		}
	}

	// The real magic
	public static function clearUnusedMemory()
	{
		for (key in keyedGraphics.keys())
		{
			if (!persistentAssets.contains(key))
			{
				var graphic:Null<FlxGraphic> = keyedGraphics.get(key);
				if (graphic != null && graphic.useCount <= 0)
					removeGraphic(key);
			}
		}

		for (key in keyedBitmaps.keys())
		{
			if (!persistentAssets.contains(key))
				removeBitmapData(key);
		}

		clearUnusedSounds();

		collect();
	}

	public static function clearStoredMemory()
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj:Null<FlxGraphic> = FlxG.bitmap._cache.get(key);
			if (obj != null && !keyedGraphics.exists(key))
			{
				destroyGraphic(obj);
			}
		}

		clearUnusedSounds();

		collect();
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
		for (key in keyedSounds.keys())
		{
			var sound:Null<Sound> = keyedSounds.get(key);
			if (!usedSounds.contains(sound) && !persistentAssets.contains(key))
				removeSound(key);
		}
	}

	// Helper functions

	public static function collect()
	{
		#if cpp
		Gc.compact();
		Gc.run(true);
		#elseif hl
		Gc.major();
		#elseif android
		Gc.run();
		#end
	}

	public static inline function isCached(id:String, map:CacheMap):Bool
		return cast(Reflect.field(Cache, 'keyed${map}'), Map<String, Dynamic>).exists(id);

	public static inline function exists(id:String):Bool
		return Assets.exists(id);

	public static inline function fromFS(id:String):Bool
		return id.contains("just_another_fnf_engine");
}

enum abstract CacheMap(String) to String
{
	var BITMAP = "Bitmaps";
	var GRAPHIC = "Graphics";
	var ATLAS = "Atlases";
	var SOUND = "Sounds";
}

typedef CachedAtlas =
{
	var frames:FlxAtlasFrames;
	var type:AtlasType;
}

enum AtlasType
{
	Sparrow;
	Packer;
}
