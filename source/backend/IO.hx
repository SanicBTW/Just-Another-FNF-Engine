package backend;

import haxe.ds.Either;
import haxe.io.Bytes;
import haxe.io.Path;
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
	public static var persistentTemp:Bool = false;

	/**
	 * The path where all the temporary files will be stored
	 */
	private static var tempPath:String = Path.join([System.userDirectory, 'jafe_files', 'temp', Random.uniqueId()]);

	/**
	 * Sets variables and creates the temporary folder
	 */
	public static function Initialize()
	{
		// Read from save
		trace('IO - Making path at $tempPath');
		FileSystem.createDirectory(tempPath);
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
			var files:Array<String> = FileSystem.readDirectory(tempPath);
			var i:Int = 0;
			while (files.length > 0)
			{
				var file:String = files[i];

				trace('Deleting $file from temp path');
				FileSystem.deleteFile(file);
				files.remove(file);

				i++;
			}
			FileSystem.deleteDirectory(tempPath);
		}
		catch (ex)
		{
			trace(ex);
		}
	}

	public static function saveFile<T>(name:String, content:T):String
	{
		var outPath:String = Path.join([tempPath, name]);
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

enum abstract FileGetType(String) to String
{
	var CONTENT = "Content";
	var BYTES = "Bytes";
}
