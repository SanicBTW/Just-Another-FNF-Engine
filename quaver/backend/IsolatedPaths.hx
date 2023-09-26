package backend;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.io.Path;
import openfl.media.Sound;
import openfl.utils.Assets;

// Inspired by ModulePaths on stable source
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
			var path:String = Path.join([localPath, file]);
			if (!sys.FileSystem.exists(path))
				throw('Failed to get $file on $localPath');

			return path;
		}
		else
		#end
		{
			return 'funkin:assets/funkin/$localPath/$file';
		}
	}

	public inline function sound(key:String):Sound
		return Cache.getSound(getPath('sounds/$key.ogg'));

	public inline function music(key:String):Sound
		return Cache.getSound(getPath('music/$key.ogg'));

	public inline function image(key:String):FlxGraphic
		return Cache.getGraphic(getPath('images/$key.png'));

	public inline function getSparrowAtlas(key:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(Cache.getGraphic(getPath('$key.png')), Cache.getText(getPath('$key.xml')));
}
