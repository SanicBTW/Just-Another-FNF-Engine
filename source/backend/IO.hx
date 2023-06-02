package backend;

import funkin.ChartLoader;
import haxe.io.Bytes;
import haxe.io.Path;
import openfl.media.Sound;
#if FS_ACCESS
import lime.app.Application;
import lime.system.System;
import sys.FileSystem;
import sys.io.File;

using StringTools;

// too lazy to comment shit now lol
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
		addFolder(NOTETYPES);
		addFolder(MUSIC);
		addFolder(SOUNDS);
		addFolder(EVENTS);

		// The idea of the mods folder is to manage its own assets and shit, basically like fof -> the engine asset tree / rolling again -> the engine asset tree but different assets etc
		// addFolder(MODS);

		for (name => path in appFolders)
		{
			trace('Checking if $name at $path exists');
			if (!FileSystem.exists(path))
				FileSystem.createDirectory(path);
		}

		Cache.collect();
	}

	public static function getSong(song:String, file:SongFile, diff:Int = 1):Dynamic
	{
		var parentPath:String = Path.join([getFolderPath(SONGS), Paths.formatString(song)]);
		if (!exists(parentPath))
			FileSystem.createDirectory(parentPath);

		switch (file)
		{
			case CHART:
				var diffString:String = ChartLoader.strDiffMap.get(diff);
				var chartPath:String = Path.join([parentPath, '${song}${diffString}.json']);
				if (!exists(chartPath))
					return null;

				return File.getContent(chartPath);
			// will read directory soon and get the best match for it (if it has like inst2410421.ogg or shit like that lol)

			case INST:
				var instPath:String = Path.join([parentPath, 'Inst.ogg']);
				if (!exists(instPath))
					return null;

				return Sound.fromFile(instPath);
			case VOICES:
				var voicesPath:String = Path.join([parentPath, 'Voices.ogg']);
				if (!exists(voicesPath))
					return null;

				return Sound.fromFile(voicesPath);
		}

		return null;
	}

	public static function saveSong(song:String, file:SongFile, content:Dynamic, diff:Int = 1):String
	{
		var parentPath:String = Path.join([getFolderPath(SONGS), Paths.formatString(song)]);
		if (!exists(parentPath))
			FileSystem.createDirectory(parentPath);

		switch (file)
		{
			case CHART:
				var diffString:String = ChartLoader.strDiffMap.get(diff);
				var chartPath:String = Path.join([parentPath, '${song}${diffString}.json']);
				if (content is Bytes)
					File.saveBytes(chartPath, content);
				else
					File.saveContent(chartPath, content);
				return chartPath;

			case INST:
				var outPath:String = Path.join([parentPath, 'Inst.ogg']);
				File.saveBytes(outPath, content); // most likely to be bytes
				return outPath;

			case VOICES:
				var outPath:String = Path.join([parentPath, 'Voices.ogg']);
				File.saveBytes(outPath, content); // most likely to be bytes
				return outPath;
		}

		return parentPath;
	}

	// Helper functions
	private static function addFolder(name:AssetFolder, parent:AssetFolder = PARENT)
		appFolders.set(name, Path.join([appFolders.get(parent), name]));

	public static inline function exists(file:String)
		return FileSystem.exists(file);

	public static inline function existsOnFolder(folder:AssetFolder = PARENT, file:String)
		return FileSystem.exists(Path.join([appFolders.get(folder), file]));

	public static inline function getFolderPath(folder:AssetFolder = PARENT)
		return appFolders.get(folder);

	public static inline function getFolderFiles(folder:AssetFolder = PARENT)
		return FileSystem.readDirectory(appFolders.get(folder));
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
	var NOTETYPES = "notetypes";
	var MUSIC = "music";
	var SOUNDS = "sounds";
	var EVENTS = "events";
	var MODS = "mods";
}

enum SongFile
{
	CHART;
	INST;
	VOICES;
}
