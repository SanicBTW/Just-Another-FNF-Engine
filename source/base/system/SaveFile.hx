package base.system;

import flixel.FlxG;
import flixel.util.FlxSave;
import lime.app.Application;

using StringTools;

#if !html5
import haxe.io.Path;
import lime.system.System;
#end

class SaveFile
{
	#if !html5
	private static var _db(default, null):SqliteKeyValue;
	#else
	private static var _save(default, null):FlxSave;
	#end

	public static function Initialize()
	{
		#if !debug
		FlxG.save.close();
		#end
		#if !html5
		_db = new SqliteKeyValue(Path.join([
			System.userDirectory,
			'${Application.current.meta.get("file")}_files',
			"settings.db"
		]), "Settings");
		#else
		_save = new FlxSave();
		_save.bind("settings", #if (flixel < "5.0.0") Application.current.meta.get("company") #end);
		#end
		SaveData.loadSettings();
	}

	public static inline function set(key:String, value:String)
	{
		#if !html5
		_db.set(key, value);
		#else
		Reflect.setField(_save.data, key, value);
		#end
	}

	public static inline function get(key:String):#if !html5 String #else Dynamic #end
	{
		#if !html5
		return _db.get(key);
		#else
		return Reflect.field(_save.data, key);
		#end
	}

	// SQLite flushes to disk everytime there's a transaction
	public static function save()
	{
		#if !html5
		_db.save();
		#else
		_save.flush(0, (_) ->
		{
			trace("Saved");
		});
		#end
	}
}
