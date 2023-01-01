import base.SoundManager;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.Assets;
import openfl.media.Sound;
#if cpp
import cpp.NativeGc;
#elseif java
import java.vm.Gc;
#end

// Make compatbile with StorageAccess
class Paths
{
	public static var currentTrackedAssets:Map<String, FlxGraphic> = new Map();
	public static var currentTrackedSounds:Map<String, Sound> = new Map();
	public static var localTrackedAssets:Array<String> = [];
	public static var dumpExclusions:Array<String> = [
		'assets/music/freakyMenu.ogg',
		#if !android 'assets/images/cursorIdle.png', 'assets/images/cursorHover.png' #end
	];

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

	public static inline function music(key:String, ?library:String):Sound
		return getSound(getPath('music/$key.ogg', library));

	public static inline function image(key:String, ?library:String):FlxGraphic
		return getGraphic(getPath('images/$key.png', library));

	public static inline function getSparrowAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));

	public static function getGraphic(file:String)
	{
		if (!Assets.exists(file))
		{
			trace('$file not found, returning null');
			return null;
		}

		if (!currentTrackedAssets.exists(file))
		{
			var newBitmap = Assets.getBitmapData(file);
			var newGraphic = FlxGraphic.fromBitmapData(newBitmap, false, file);
			currentTrackedAssets.set(file, newGraphic);
		}
		localTrackedAssets.push(file);
		return currentTrackedAssets.get(file);
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
				trace(key);
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

		runGC();
		SoundManager.clearSoundList();
	}

	public static function clearStoredMemory()
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				trace(key);
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
				trace(key);
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		localTrackedAssets = [];
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
