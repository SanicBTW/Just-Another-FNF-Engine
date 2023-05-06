package backend;

import haxe.ds.Either;
import haxe.io.Bytes;
import haxe.io.Path;
import lime.system.System;

class IO
{
	/**
	 * If true, temporary files won't be deleted upon closing the engine
	 */
	public static var persistentTemp:Bool = false;

	/**
	 * The path where all the temporary files will be stored
	 */
	public static var tempPath:String = Path.join([System.applicationStorageDirectory, Random.uniqueId()]);

	/**
	 * Removes the temporary files path, only called upon closing
	 */
	public static function cleanTemp()
	{
		if (persistentTemp)
		{
			trace("IO - Not deleting temporary files");
			return;
		}

		trace("Deleting temporary files");
	}

	public static function saveFile(name:String, content:Either<String, Bytes>)
	{
		var outPath:String = Path.join([tempPath, name]);

		if (content is String) {}
	}
}
