package base.system;

import flixel.FlxG;
import flixel.util.FlxSave;
import haxe.io.Path;
import lime.app.Application;
import lime.system.System;

using StringTools; // just manages save shit lol

class DatabaseManager
{
	#if !html5
	private static var _db(default, null):SqliteKeyValue;
	#else
	private static var _save(default, null):FlxSave;
	#end

	public static function Initialize()
	{
		#if !html5
		#if !debug
		FlxG.save.close();
		#end
		_db = new SqliteKeyValue(Path.join([
			System.applicationStorageDirectory.replace("MyCompany", Application.current.meta.get("company"))
				.replace("MyApplication", Application.current.meta.get("file")),
			"engine_settings.db"
		]), "EngineSettings");
		#else
		_save = new FlxSave();
		_save.bind("db", null);
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

	public static inline function get(key:String):Dynamic
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
		#if html5
		_save.flush(0, (_) ->
		{
			trace("Saved");
		});
		#end
	}
}
