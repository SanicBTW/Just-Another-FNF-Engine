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

// Make compatbile with StorageAccess
class Paths
{
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
		return Cache.getSound(getPath('sounds/$key.ogg', library));
	}

	public static inline function font(key:String)
		return getPath('fonts/$key');

	public static inline function music(key:String, ?library:String):Sound
		return Cache.getSound(getPath('music/$key.ogg', library));

	public static inline function image(key:String, ?library:String):FlxGraphic
		return Cache.getGraphic(getPath('images/$key.png', library));

	public static inline function inst(song:String):Sound
		return Cache.getSound(getPath('${formatString(song)}/Inst.ogg', "songs"));

	public static inline function voices(song:String):Sound
		return Cache.getSound(getPath('${formatString(song)}/Voices.ogg', "songs"));

	public static inline function getSparrowAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));

	// force the path to search for an image without images/
	public static inline function getForcedSparrowAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSparrow(Cache.getGraphic(getPath('$key.png', library)), file('$key.xml', library));

	public static inline function formatString(string:String)
		return string.toLowerCase().replace(" ", "-");
}
