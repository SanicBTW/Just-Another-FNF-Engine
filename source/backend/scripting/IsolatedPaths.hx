package backend.scripting;

import Paths.Libraries;
import backend.io.Path;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;
import openfl.utils.Assets;

// https://github.com/SanicBTW/Forever-Engine-Archive/blob/rewrite/source/Paths.hx#L17
class IsolatedPaths
{
	private var localPath:String;

	public function new(localPath:String)
	{
		this.localPath = localPath;
	}

	public function getPath(file:String):String
	{
		#if FS_ACCESS
		if (Cache.fromFS(localPath))
		{
			var path:String = Path.join(localPath, file);
			if (!sys.FileSystem.exists(path))
				throw('Failed to get $file on $localPath');

			return path;
		}
		else
		#end
		{
			@:privateAccess
			var libPath:String = '${Paths._library}:assets/${Paths._library}/$localPath/$file';
			if (Assets.exists(libPath))
				return libPath;

			return '${Libraries.DEFAULT}:assets/${Libraries.DEFAULT}/$localPath/$file';
		}
	}

	public inline function sound(key:String):Sound
		return getSound(key, "sounds");

	public inline function music(key:String):Sound
		return getSound(key, "music");

	public inline function image(key:String):FlxGraphic
		return getGraphic(key, "images");

	public inline function getSparrowAtlas(key:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(Cache.getGraphic(getPath('$key.png')), Cache.getText(getPath('$key.xml')));

	// Helper functions for better support
	public inline function getGraphic(key:String, folder:String):FlxGraphic
		return Cache.getGraphic(getPath('$folder/$key.png'));

	public inline function getSound(key:String, folder:String):Sound
		return Cache.getSound(getPath('$folder/$key.ogg'));
}
