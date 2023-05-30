package backend;

import haxe.io.Bytes;
import haxe.io.Path;
#if FS_ACCESS
import lime.app.Application;
import lime.system.System;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class IO
{
	/**
	 * The application folders where files are stored
	 */
	private static var appFolders:Map<AssetFolder, String> = new Map();

	/**
	 * Sets folders
	 */
	public static function Initialize()
	{
		// Set the parent folder, in future versions it will be changeable
		appFolders.set(PARENT, Path.join([System.documentsDirectory, 'just_another_fnf_engine']));

		addFolder(DATA);
		addFolder(SONGS);
		addFolder(IMAGES);
		addFolder(CHARACTERS);
		addFolder(STAGES);
		addFolder(MUSIC);
		addFolder(SOUNDS);

		// The idea of the mods folder is to manage its own assets and shit, basically like fof -> the engine asset tree / rolling again -> the engine asset tree but different assets etc
		addFolder(MODS);

		for (name => path in appFolders)
		{
			trace('Checking if $name at $path exists');
			if (!FileSystem.exists(path))
				FileSystem.createDirectory(path);
		}

		Cache.collect();
	}

	private static function addFolder(name:AssetFolder, parent:AssetFolder = PARENT)
		appFolders.set(name, Path.join([appFolders.get(parent), name]));

	// Helper functions
	public static inline function exists(folder:AssetFolder) {}
}
#else
#end
enum abstract AssetFolder(String) to String
{
	var PARENT = "parent";
	var DATA = "data";
	var SONGS = "songs";
	var IMAGES = "images";
	var CHARACTERS = "characters";
	var STAGES = "stages";
	var MUSIC = "music";
	var SOUNDS = "sounds";
	var MODS = "mods";
}
