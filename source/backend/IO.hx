package backend;

#if FS_ACCESS
import backend.io.Path;
import funkin.ChartLoader;
import haxe.io.Bytes;
import lime.system.System;
import openfl.media.Sound;
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
		#if !android
		appFolders.set(PARENT, Path.join(System.documentsDirectory, 'just_another_fnf_engine'));
		#else
		// for good measure lets save that data inside obb
		appFolders.set(PARENT, Path.join(android.content.Context.getObbDir()));
		#end

		addFolder(DATA);
		addFolder(SONGS);
		addFolder(IMAGES);
		addFolder(CHARACTERS);
		addFolder(STAGES);
		addFolder(NOTETYPES);
		addFolder(MUSIC);
		addFolder(SOUNDS);
		addFolder(EVENTS);
		addFolder(SCRIPTS);

		// because my dumb ass cant do a proper check to create folders on parsing (old Qua.hx from scrolling&backend-rewrite branch)
		addFolder(QUAVER);
		addFolder(OSU);

		// The idea of the mods folder is to manage its own assets and shit, basically like fof -> the engine asset tree / rolling again -> the engine asset tree but different assets etc
		// yo new idea on the enum declaration fr fr fr shits fire
		// addFolder(MODS);

		for (name => path in appFolders)
		{
			trace('Checking if $name folder exists at $path');
			if (!FileSystem.exists(path))
				FileSystem.createDirectory(path);
		}

		Cache.collect();
	}

	// add quality percentage for the stuff
	public static function getSong(song:String, file:SongFile, diff:Int = 1):Dynamic
	{
		var parentPath:String = Path.join(getFolderPath(SONGS), Paths.formatString(song));
		if (!exists(parentPath))
			FileSystem.createDirectory(parentPath);

		switch (file)
		{
			case CHART:
				var diffString:String = ChartLoader.strDiffMap.get(diff);
				var chartPath:String = Path.join(parentPath, '${song}${diffString}.json');
				if (!exists(chartPath))
					return null;

				return File.getContent(chartPath);
			// will read directory soon and get the best match for it (if it has like inst2410421.ogg or shit like that lol)

			case INST:
				var instPath:String = Path.join(parentPath, 'Inst.ogg');
				if (!exists(instPath))
					return null;

				return Sound.fromFile(instPath);
			case VOICES:
				var voicesPath:String = Path.join(parentPath, 'Voices.ogg');
				if (!exists(voicesPath))
					return null;

				return Sound.fromFile(voicesPath);
		}

		return null;
	}

	public static function saveSong(song:String, file:SongFile, content:Dynamic, diff:Int = 1):String
	{
		var parentPath:String = Path.join(getFolderPath(SONGS), Paths.formatString(song));
		if (!exists(parentPath))
			FileSystem.createDirectory(parentPath);

		switch (file)
		{
			case CHART:
				var diffString:String = ChartLoader.strDiffMap.get(diff);
				var chartPath:String = Path.join(parentPath, '${song}${diffString}.json');
				if (content is Bytes)
					File.saveBytes(chartPath, content);
				else
					File.saveContent(chartPath, content);
				return chartPath;

			case INST:
				var outPath:String = Path.join(parentPath, 'Inst.ogg');
				File.saveBytes(outPath, content); // most likely to be bytes
				return outPath;

			case VOICES:
				var outPath:String = Path.join(parentPath, 'Voices.ogg');
				File.saveBytes(outPath, content); // most likely to be bytes
				return outPath;
		}

		return parentPath;
	}

	// Helper functions
	private static function addFolder(name:AssetFolder, parent:AssetFolder = PARENT)
		appFolders.set(name, Path.join(appFolders.get(parent), name));

	public static function existsOnFolder(folder:AssetFolder = PARENT, file:String):Bool
		return exists(Path.join(appFolders.get(folder), file));

	public static function getFolderPath(folder:AssetFolder = PARENT):String
		return appFolders.get(folder);

	public static function getFolderFiles(folder:AssetFolder = PARENT):Array<String>
		return readDirectory(appFolders.get(folder));

	// Wrapper functions for native FileSystem
	public static function exists(file:String):Bool
		return FileSystem.exists(file);

	public static function createDirectory(path:String):Void
		return FileSystem.createDirectory(path);

	public static function deleteFile(path:String):Void
		return FileSystem.deleteFile(path);

	public static function deleteDirectory(path:String):Void
		return FileSystem.deleteDirectory(path);

	public static function readDirectory(path:String):Array<String>
		return FileSystem.readDirectory(path);

	// Wrapper functions for native File
	public static function getContent(path:String):String
		return File.getContent(path);

	public static function getBytes(path:String):Bytes
		return File.getBytes(path);

	public static function saveContent(path:String, content:String):Void
		return File.saveContent(path, content);

	public static function saveBytes(path:String, bytes:Bytes):Void
		return File.saveBytes(path, bytes);
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
	var SCRIPTS = "scripts"; // Global Scripts, will be kept in memory for the rest of the game (or atleast try to)
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
