package;

import base.SoundManager;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;
import openfl.system.System;
#if cpp
import cpp.NativeGc;
#elseif android
import java.vm.Gc;
#end

// add network shit
class Cache
{
	// graphics related stuff
	private static var trackedBitmaps:Map<String, BitmapData> = new Map();
	private static var trackedGraphics:Map<String, FlxGraphic> = new Map();
	private static var trackedTextures:Map<String, Texture> = new Map();

	// audio shit
	private static var trackedSounds:Map<String, Sound> = new Map();

	// network
	private static var trackedNetworkCache:Map<String, Dynamic> = new Map();

	// tracking and exclusions
	private static var localTracked:Array<String> = [];
	private static var dumpExclusions:Array<String> = ['assets/music/freakyMenu.ogg', 'fonts:assets/fonts/VCR/VCR.png'];

	public static function getBitmap(file:String):Null<BitmapData>
	{
		if (!Assets.exists(file))
		{
			trace('$file not found, returning null');
			return null;
		}

		return setBitmap(file, Assets.getBitmapData(file));
	}

	public static function setBitmap(id:String, ?bitmap:BitmapData):BitmapData
	{
		if (!trackedBitmaps.exists(id) && bitmap != null)
			trackedBitmaps.set(id, bitmap);
		pushTracked(id);
		return trackedBitmaps.get(id);
	}

	public static function disposeBitmap(id:String)
	{
		var obj:Null<BitmapData> = trackedBitmaps.get(id);
		if (obj != null)
		{
			obj.dispose();
			obj.disposeImage();
			obj = null;
			trackedBitmaps.remove(id);
		}
	}

	public static function getGraphic(file:String, textureCompression:Bool = #if !html5 true #else false #end):Null<FlxGraphic>
	{
		if (!Assets.exists(file))
		{
			trace('$file not found, returning null');
			return null;
		}

		if (!trackedGraphics.exists(file))
		{
			var newBitmap:BitmapData = getBitmap(file);
			var newGraphic:FlxGraphic;
			if (textureCompression)
			{
				var texture:Texture = getTexture(file, newBitmap);
				newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, file);
			}
			else
				newGraphic = FlxGraphic.fromBitmapData(newBitmap, false, file);
			trackedGraphics.set(file, newGraphic);
		}
		pushTracked(file);
		return trackedGraphics.get(file);
	}

	public static function getTexture(file:String, bitmap:BitmapData):Texture
	{
		if (!trackedTextures.exists(file))
		{
			var texture:Texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true, 0);
			texture.uploadFromBitmapData(bitmap);
			trackedTextures.set(file, texture);
			bitmap.dispose();
			bitmap.disposeImage();
			bitmap = null;
		}
		pushTracked(file);
		return trackedTextures.get(file);
	}

	public static function getSound(file:String):Null<Sound>
	{
		if (!Assets.exists(file))
		{
			trace('$file not found, returning null');
			return null;
		}

		if (!trackedSounds.exists(file))
			trackedSounds.set(file, Assets.getSound(file));
		pushTracked(file);
		return trackedSounds.get(file);
	}

	public static function setNetworkCache(id:String, ?toCache:Dynamic):Null<Dynamic>
	{
		if (!trackedNetworkCache.exists(id) && toCache != null)
			trackedNetworkCache.set(id, toCache);
		pushTracked(id);
		return trackedNetworkCache.get(id);
	}

	public static function pushTracked(file:String)
	{
		if (!localTracked.contains(file))
			localTracked.push(file);
	}

	public static function clearUnusedMemory()
	{
		for (key in trackedGraphics.keys())
		{
			if (!localTracked.contains(key) && !dumpExclusions.contains(key))
			{
				var obj:Null<FlxGraphic> = trackedGraphics.get(key);
				@:privateAccess
				if (obj != null)
				{
					Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					trackedGraphics.remove(key);
					obj.dump();
					obj.destroy();
				}
			}
		}

		for (key in trackedTextures.keys())
		{
			if (!localTracked.contains(key) && !dumpExclusions.contains(key))
			{
				var obj:Texture = trackedTextures.get(key);
				if (obj != null)
				{
					obj.dispose();
					obj = null;
					trackedTextures.remove(key);
				}
			}
		}

		for (key in trackedBitmaps.keys())
		{
			if (!localTracked.contains(key) && !dumpExclusions.contains(key))
			{
				var obj:Null<BitmapData> = trackedBitmaps.get(key);
				if (obj != null)
				{
					obj.dispose();
					obj.disposeImage();
					obj = null;
					trackedBitmaps.remove(key);
				}
			}
		}

		for (key in trackedNetworkCache.keys())
		{
			if (!localTracked.contains(key) && !dumpExclusions.contains(key))
			{
				trackedNetworkCache.remove(key);
				key = null;
			}
		}

		runGC();
	}

	public static function clearStoredMemory()
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj:Null<FlxGraphic> = FlxG.bitmap._cache.get(key);
			if (obj != null && !trackedGraphics.exists(key))
			{
				Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.dump();
				obj.destroy();
			}
		}

		for (key in trackedSounds.keys())
		{
			var obj:Null<Sound> = trackedSounds.get(key);
			if (obj != null && !localTracked.contains(key) && !dumpExclusions.contains(key))
			{
				obj.close();
				obj = null;
				Assets.cache.clear(key);
				trackedSounds.remove(key);
			}
		}

		localTracked = [];
		SoundManager.clearSoundList();
	}

	public static inline function runGC()
	{
		#if cpp
		NativeGc.compact();
		NativeGc.run(true);
		#elseif android
		Gc.run();
		#else
		System.gc();
		#end
	}
}
