package;

import backend.Cache;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Exception;
import lime.app.Future;
import openfl.Assets;
import openfl.media.Sound;
import openfl.utils.AssetLibrary;
import openfl.utils.AssetType;

using StringTools;

class Paths
{
	private static var _library:Libraries = DEFAULT;
	private static var _oldLibrary:Libraries = _library;

	// Open a substate that indicates the loading state?
	// If the new library is the default one, it will unload the previous one
	// Search for a better way to change library (crashes after a couple of changes)
	// You dummy it crashed because we were returning null if we tried to change to the same library :skull: now its fixed and doesnt seem to be crashing anymore
	public static function changeLibrary(newLibrary:Libraries, onFinish:Null<AssetLibrary>->Void)
	{
		if (_library == newLibrary)
		{
			onFinish(cast Assets.getLibrary(_library));
			return;
		}

		if (Assets.hasLibrary(_oldLibrary) && _oldLibrary != DEFAULT)
		{
			trace('Unloading $_oldLibrary');
			Assets.unloadLibrary(_oldLibrary);
		}

		if (!Assets.hasLibrary(newLibrary))
		{
			var loadLib:Future<AssetLibrary> = Assets.loadLibrary(newLibrary);
			loadLib.onComplete((lib:AssetLibrary) ->
			{
				_oldLibrary = _library;
				_library = newLibrary;
				onFinish(lib);
			});
			loadLib.onError((err) ->
			{
				throw new Exception('Error while loading $newLibrary: $err');
			});
		}
	}

	public static function getPath(file:String, type:AssetType):String
	{
		var path:String = '$_library:assets/$_library/$file';
		if (Assets.exists(path, type))
			return path;

		// Returns the preload path
		return '${Libraries.DEFAULT}:assets/${Libraries.DEFAULT}/$file';
	}

	// ofl - open fl filter / ffl - folder filter loll - tested in my Mic'd Up port for HTML5, shits fresh and workin fine :sunglasses:
	public static function getLibraryFiles(?ofl:String, ?ffl:String):Array<String>
	{
		if (!Assets.hasLibrary(_library))
			changeLibrary(_library, (_) -> {});

		var files:Array<String> = Assets.getLibrary(_library).list(ofl);
		var finalRet:Array<String> = [];

		if (ffl != null)
		{
			for (file in files)
			{
				if (file.contains(ffl))
				{
					finalRet.push(file);
				}
			}
		}
		else
			finalRet = files;

		return finalRet;
	}

	public static inline function file(file:String, type:AssetType = TEXT)
		return getPath(file, type);

	public static inline function text(path:String):String
		return Cache.getText(path);

	public static inline function sound(key:String):Sound
		return Cache.getSound(getPath('sounds/$key.ogg', SOUND));

	public static inline function font(key:String):String
		return getPath('fonts/$key', FONT);

	public static inline function music(key:String):Sound
		return Cache.getSound(getPath('music/$key.ogg', MUSIC));

	public static inline function image(key:String):FlxGraphic
		return Cache.getGraphic(getPath('images/$key.png', IMAGE));

	public static inline function inst(song:String):Sound
		return Cache.getSound(getPath('songs/${formatString(song)}/Inst.ogg', MUSIC));

	public static inline function voices(song:String):Sound
		return Cache.getSound(getPath('songs/${formatString(song)}/Voices.ogg', MUSIC));

	public static inline function getSparrowAtlas(key:String, ?folder:String = 'images'):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(Cache.getGraphic(getPath('$folder/$key.png', IMAGE)), Cache.getText(getPath('$folder/$key.xml', TEXT)));

	public static inline function txt(key:String):String
		return text(getPath('data/$key.txt', TEXT));

	public static inline function formatString(string:String)
		return string.toLowerCase().replace(" ", "-");
}

enum abstract Libraries(String) to String
{
	var DEFAULT = "funkin";
	var QUAVER = "quaver";
	var FOF = "fof";
	var SIXH = "6h";
}

enum abstract BGTheme(String) to String
{
	var DEFAULT = "default";
	var SANCO = "sanco";
}
