package backend;

import haxe.ds.Either;
import haxe.io.Bytes;
import haxe.io.Path;
#if sys
import lime.app.Application;
import lime.system.System;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class IO
{
	/**
	 * If true, temporary files won't be deleted upon closing the engine
	 */
	public static var persistentTemp:Bool = true;

	/**
	 * The path where all the temporary files will be stored
	 */
	private static var appPath:String = Path.join([
		System.userDirectory,
		'jafe_files',
		(persistentTemp)
		? 'persistent' : 'temp_${Random.uniqueId()}'
	]);

	/**
	 * Sets variables and creates the temporary folder
	 */
	public static function Initialize()
	{
		// Read from save
		trace('IO - Making path at $appPath');
		if (persistentTemp && !FileSystem.exists(appPath) || !FileSystem.exists(appPath))
			FileSystem.createDirectory(appPath);
	}

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

		try
		{
			for (file in FileSystem.readDirectory(appPath))
			{
				trace('Deleting $file from temp path');
				FileSystem.deleteFile(file);
			}
			FileSystem.deleteDirectory(appPath);
		}
		catch (ex)
		{
			trace(ex);
		}
	}

	public static function saveFile<T>(name:String, content:T):String
	{
		var outPath:String = Path.join([appPath, name]);
		trace('Saving to $outPath');

		if (content is String)
			File.saveContent(outPath, cast content);
		if (content is Bytes)
			File.saveBytes(outPath, cast content);

		return outPath;
	}

	public static function getFile(file:String, method:FileGetType):Dynamic
	{
		trace('Getting $file');

		switch (method)
		{
			case CONTENT:
				return File.getContent(file);

			case BYTES:
				return File.getBytes(file);
		}

		return null;
	}
}
#else
// Only copy fields to avoid a bunch of compilation shits
class IO
{
	public static var persistentTemp:Bool = false;

	private static var appPath:String = "";

	public static function Initialize() {}

	public static function cleanTemp() {}

	public static function saveFile<T>(name:String, content:T) {}

	public static function getFile(file:String, method:FileGetType) {}
}
#end

enum abstract FileGetType(String) to String
{
	var CONTENT = "Content";
	var BYTES = "Bytes";
}
