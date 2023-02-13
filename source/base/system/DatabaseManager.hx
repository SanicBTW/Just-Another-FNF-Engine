package base.system;

import flixel.FlxG;
import lime.app.Application;

using StringTools;

#if sys
import haxe.io.Path;
import lime.system.System;
import sys.db.Connection;
import sys.db.Sqlite;
#end
#if html5
import js.Browser;
import js.html.Storage;
#end

class DatabaseManager
{
	public static var DatabasePath(default, null):String;
	public static var Connection(default, null):#if sys Connection #else Storage #end;

	public static function Initialize()
	{
		FlxG.save.close();

		#if sys
		DatabasePath = Path.join([
			System.applicationStorageDirectory.replace("MyCompany", Application.current.meta.get("company"))
				.replace("MyApplication", Application.current.meta.get("file")),
			"engine.db"
		]);
		trace("Database opening at " + DatabasePath);
		Connection = Sqlite.open(DatabasePath);
		#else
		DatabasePath = '${Application.current.meta.get("company")}_${Application.current.meta.get("file")}.save';
		Connection = Browser.getLocalStorage();
		trace("Local storage setting to " + DatabasePath);
		#end
	}

	// this method kind of sucks maybe something like Connection.setItem(DatabasePath, "[key, value, type],[key, value, type]");
	public static function set(key:String, value:Null<String>)
	{
		trace('Setting $key with $value');
		#if html5
		Connection.setItem('${key}_${DatabasePath}', '$value');
		#end
	}

	public static function get(key:String):Dynamic
	{
		trace('Getting $key');
		#if html5
		trace(Connection.getItem('${key}_${DatabasePath}'));
		return Connection.getItem('${key}_${DatabasePath}');
		#end
	}
}
