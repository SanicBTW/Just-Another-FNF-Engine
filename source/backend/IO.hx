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

		// because my dumb ass cant do a proper check to create folders on parsing (old Qua.hx from scrolling&backend-rewrite branch)
		addFolder(QUAVER);
		addFolder(OSU);

		// The idea of the mods folder is to manage its own assets and shit, basically like fof -> the engine asset tree / rolling again -> the engine asset tree but different assets etc
		// yo new idea on the enum declaration fr fr fr shits fire
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

	public static inline function exists(file:String):Bool
		return FileSystem.exists(file);

	public static inline function existsOnFolder(folder:AssetFolder = PARENT, file:String):Bool
		return FileSystem.exists(Path.join([appFolders.get(folder), file]));

	public static inline function getFolderPath(folder:AssetFolder = PARENT):String
		return appFolders.get(folder);

	public static inline function getFolderFiles(folder:AssetFolder = PARENT):Array<String>
		return FileSystem.readDirectory(appFolders.get(folder));
}
#else
class IO
{
	private static var appFolders:Map<AssetFolder, String> = new Map();

	public static function Initialize() {}

	public static function getSong(song:String, file:SongFile, diff:Int = 1):Dynamic
		return null;

	public static function saveSong(song:String, file:SongFile, content:Dynamic, diff:Int = 1):String
		return '';

	private static function addFolder(name:AssetFolder, parent:AssetFolder = PARENT) {}

	public static inline function exists(file:String):Bool
		return false;

	public static inline function existsOnFolder(folder:AssetFolder = PARENT, file:String):Bool
		return false;

	public static inline function getFolderPath(folder:AssetFolder = PARENT):String
		return '';

	public static inline function getFolderFiles(folder:AssetFolder = PARENT):Array<String>
		return [];
}
#end

enum abstract AssetFolder(String) to String
{
	var PARENT = "parent";
	// base file tree
	var DATA = "data";
	var SONGS = "songs";
	var IMAGES = "images";
	var CHARACTERS = "characters";
	var STAGES = "stages";
	var NOTETYPES = "notetypes";
	var MUSIC = "music";
	var SOUNDS = "sounds";
	var EVENTS = "events";
	// it will be hard to implement a good system for this but should be just like libraries (maybe I will add a .ini system that builds file references and it will be used for loading and shit??? sounds cool tho)
	var MODS = "mods";
	// Chart support and convert (will move .mp3 files into here)
	var QUAVER = "quaver";
	var OSU = "osu!";
}

enum SongFile
{
	CHART;
	INST;
	VOICES;
}
