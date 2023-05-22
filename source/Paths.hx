package;

import backend.Cache;
import backend.IO;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Exception;
import haxe.io.Bytes;
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
	public static function changeLibrary(newLibrary:Libraries, onFinish:Void->Void)
	{
		trace('\nTarget library $newLibrary \nCurrent library $_library \nOld library $_oldLibrary');
		if (_library == newLibrary)
			onFinish();

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
				trace('Finished loading ${newLibrary}');
				_oldLibrary = _library;
				_library = newLibrary;
				onFinish();
			});
			loadLib.onProgress((loaded:Int, total:Int) ->
			{
				trace('$loaded / $total (${loaded / total})');
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
		return '${Libraries.DEFAULT}:assets/funkin/$file';
	}

	public static function getLibraryFiles(?filter:String):Array<String>
	{
		if (!Assets.hasLibrary(_library))
			changeLibrary(_library, () -> {});

		return Assets.getLibrary(_library).list(filter);
	}

	public static inline function file(file:String, type:AssetType = TEXT)
		return getPath(file, type);

	public static inline function text(key:String):String
		return Assets.getText(key);

	// better parsing soon ig
	public static inline function module(key:String):String
		return file(key.endsWith(".hxs") ? key : '$key.hxs');

	public static inline function sound(key:String):Sound
		return Cache.getSound(getPath('sounds/$key.ogg', SOUND));

	public static inline function font(key:String)
		return 'assets/fonts/$key';

	public static inline function music(key:String):Sound
		return Cache.getSound(getPath('music/$key.ogg', MUSIC));

	public static inline function image(key:String):FlxGraphic
		return Cache.getGraphic(getPath('images/$key.png', IMAGE));

	public static function inst(song:String):Sound
	{
		#if (native || FS_ACCESS)
		if (song.contains("temp") || song.contains("persistent"))
		{
			song = '${song}_inst.ogg';

			var shitBytes:Bytes = IO.getFile(song, BYTES);

			var sound:Sound = new Sound();
			sound.loadCompressedDataFromByteArray(shitBytes, shitBytes.length);
			return Cache.set(sound, SOUND, song);
		}
		else
			return Cache.getSound(getPath('songs/${formatString(song)}/Inst.ogg', MUSIC));
		#else
		return Cache.getSound(getPath('songs/${formatString(song)}/Inst.ogg', MUSIC));
		#end
	}

	public static function voices(song:String):Sound
	{
		#if (native || FS_ACCESS)
		if (song.contains("temp") || song.contains("persistent"))
		{
			song = '${song}_voices.ogg';

			var shitBytes:Bytes = IO.getFile(song, BYTES);

			var sound:Sound = new Sound();
			sound.loadCompressedDataFromByteArray(shitBytes, shitBytes.length);
			return Cache.set(sound, SOUND, song);
		}
		else
			return Cache.getSound(getPath('songs/${formatString(song)}/Voices.ogg', MUSIC));
		#else
		return Cache.getSound(getPath('songs/${formatString(song)}/Voices.ogg', MUSIC));
		#end
	}

	public static inline function getSparrowAtlas(key:String, ?folder:String = 'images'):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(Cache.getGraphic(getPath('$folder/$key.png', IMAGE)), getPath('$folder/$key.xml', IMAGE));

	public static inline function formatString(string:String)
		return string.toLowerCase().replace(" ", "-");
}

enum abstract Libraries(String) to String
{
	var DEFAULT = "funkin";
	var FOF = "fof";
	var SIXH = "6h";
}
