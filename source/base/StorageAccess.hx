package base;

import haxe.io.Path;
import lime.system.System;

using StringTools;

#if FS_ACCESS
import sys.FileSystem;
import sys.io.File;
#end

class StorageAccess
{
	private static var directories:Map<Folders, String> = new Map();

	public static function checkDirectories(customDirectory:Null<String> = null)
	{
		#if FS_ACCESS
		#end
	}
}

enum abstract Folders(String) to String
{
	var MAIN = "main";
	var DATA = "data";
	var SONGS = "songs";
	var IMAGES = "images";
	var MUSIC = "music";
	var SOUNDS = "sounds";
}
