package;

import base.SoundManager;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;

using StringTools;

#if cpp
import cpp.NativeGc;
#elseif java
import java.vm.Gc;
#end

// Make compatbile with StorageAccess
class Paths
{
	public static var currentTrackedAssets:Map<String, FlxGraphic> = new Map();
	public static var currentTrackedTextures:Map<String, Texture> = new Map();
	public static var currentTrackedSounds:Map<String, Sound> = new Map();
	public static var localTrackedAssets:Array<String> = [];
	public static var dumpExclusions:Array<String> = ['assets/music/freakyMenu.ogg',];

	private static var currentLevel:String;

	public static function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?library:Null<String> = null)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = "";
			if (currentLevel != "shared")
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (Assets.exists(levelPath))
					return levelPath;
				else
					trace('Asset at path $levelPath doesn\'t exist (PATHS - CURRENT LEVEL)');
			}

			levelPath = getLibraryPathForce(file, "");
			if (Assets.exists(levelPath))
				return levelPath;
			else
				trace('Asset at path $levelPath doesn\'t exist (PATHS - CURRENT LEVEL SHARED)');
		}

		return getPreloadPath(file);
	}

	public static inline function getLibraryPath(file:String, library:String = "default")
		return (library == "default" ? getPreloadPath(file) : getLibraryPathForce(file, library));

	private static inline function getLibraryPathForce(file:String, library:String)
		return '$library:assets/$library/$file';

	public static inline function getPreloadPath(file:String)
		return 'assets/$file';

	public static inline function file(file:String, ?library:String)
		return getPath(file, library);

	public static function sound(key:String, ?library:String):Sound
	{
		return getSound(getPath('sounds/$key.ogg', library));
	}

	public static inline function font(key:String)
		return getPath('fonts/$key');

	public static inline function music(key:String, ?library:String):Sound
		return getSound(getPath('music/$key.ogg', library));

	public static inline function image(key:String, ?library:String):FlxGraphic
		return getGraphic(getPath('images/$key.png', library));

	public static inline function inst(song:String):Sound
		return getSound(getPath('${formatString(song)}/Inst.ogg', "songs"));

	public static inline function voices(song:String):Sound
		return getSound(getPath('${formatString(song)}/Voices.ogg', "songs"));

	public static inline function getSparrowAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));

	// force the path to search for an image without images/
	public static inline function getForcedSparrowAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSparrow(getGraphic(getPath('$key.png', library)), file('$key.xml', library));

	public static inline function formatString(string:String)
		return string.toLowerCase().replace(" ", "-");

	public static function getGraphic(file:String, textureCompression:Bool = #if !html5 true #else false #end)
	{
		if (!Assets.exists(file))
		{
			trace('$file not found, returning null');
			return null;
		}

		if (!currentTrackedAssets.exists(file))
		{
			var newBitmap = Assets.getBitmapData(file);
			var newGraphic:FlxGraphic;
			if (textureCompression)
			{
				var texture:Texture = getTexture(file, newBitmap);
				newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, file);
			}
			else
				newGraphic = FlxGraphic.fromBitmapData(newBitmap, false, file);
			currentTrackedAssets.set(file, newGraphic);
		}
		localTrackedAssets.push(file);
		return currentTrackedAssets.get(file);
	}

	public static function getTexture(file:String, bitmap:BitmapData)
	{
		if (!currentTrackedTextures.exists(file))
		{
			var texture:Texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true, 0);
			texture.uploadFromBitmapData(bitmap);
			currentTrackedTextures.set(file, texture);
			bitmap.dispose();
			bitmap.disposeImage();
			bitmap = null;
		}
		// dont push to localtracked because its already pushed on getGraphic
		return currentTrackedTextures.get(file);
	}

	public static function getSound(file:String)
	{
		if (!Assets.exists(file))
		{
			trace('$file not found, returning null');
			return null;
		}

		if (!currentTrackedSounds.exists(file))
			currentTrackedSounds.set(file, Assets.getSound(file));
		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
	}

	public static function clearUnusedMemory()
	{
		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					currentTrackedAssets.remove(key);
					obj.dump();
					obj.destroy();
				}
			}
		}

		for (key in currentTrackedTextures.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedTextures.get(key);
				if (obj != null)
				{
					obj.dispose();
					obj = null;
					currentTrackedTextures.remove(key);
				}
			}
		}

		runGC();
	}

	public static function clearStoredMemory()
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.dump();
				obj.destroy();
			}
		}

		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		localTrackedAssets = [];
		SoundManager.clearSoundList();
	}

	// who the fuck uses hashlink or neko lol
	public static inline function runGC()
	{
		#if cpp
		NativeGc.compact();
		NativeGc.run(true);
		#elseif java
		Gc.run();
		#end
	}
}
