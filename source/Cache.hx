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
import openfl.display3D.textures.Texture;
import openfl.media.Sound;
import openfl.utils.Assets;

using StringTools;

#if cpp
import cpp.vm.Gc;
#elseif android
import java.vm.Gc;
#end

// Rewritten completely and using some FlatyEngine code
// This manages local assets (game folder assets) and will only store external assets through another class that will be called in Paths
// Holy shit it actually improved performance a lot holy shit
// Doesn't save frames, only graphics
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

	// Use GPU to render textures
	public static var gpuRender:Bool = false;

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

		if (gpuRender)
			newBitmap = BitmapData.fromTexture(getTexture(id, newBitmap));

		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, id);
		keyedAssets.set(id, newGraphic);

		// Return graphic on first call
		return newGraphic;
	}

	public static function getTexture(id:String, bitmap:BitmapData):Texture
	{
		if (isCached(id))
			return keyedAssets.get(id);

		var texture:Texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true, 0);
		texture.uploadFromBitmapData(bitmap);
		removeBitmapData(id);

		keyedAssets.set(id, texture);

		return texture;
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

	// Cleaning functions - returns a bool indicating that it has been cleaned successfully
	public static function removeBitmapData(id:String):Bool
	{
		var bitmapD:Null<BitmapData> = keyedAssets.get(id);
		if (bitmapD != null)
		{
			bitmapD.dispose();
			bitmapD = null;
			keyedAssets.remove(id);
			return true;
		}
		return false;
	}

	public static function removeGraphic(id:String):Bool
	{
		var graphic:Null<FlxGraphic> = keyedAssets.get(id);
		@:privateAccess
		if (graphic != null)
		{
			Assets.cache.removeBitmapData(id);
			FlxG.bitmap._cache.remove(id);
			graphic.destroy();
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
			graphic.bitmap.dispose();
			FlxG.bitmap.remove(graphic);
		}
	}

	public static function clearUnusedMemory()
	{
		for (key in keyedAssets.keys())
		{
			var obj:Null<Dynamic> = keyedAssets.get(key);
			if (!persistentAssets.contains(key))
			{
				if (obj is FlxGraphic)
				{
					var graphic:FlxGraphic = obj;
					if (graphic.useCount <= 0)
						removeGraphic(key);
				}

				if (obj is Texture)
				{
					var texture:Texture = obj;
					if (texture != null)
					{
						texture.dispose();
						keyedAssets.remove(key);
					}
				}

				if (obj is BitmapData)
					removeBitmapData(key);
			}
		}

		clearUnusedSounds();

		runGC();
	}

	public static function clearStoredMemory()
	{
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
