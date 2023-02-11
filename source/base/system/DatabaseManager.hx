package base.system;

import flixel.FlxG;
import lime.app.Application;

using StringTools;

#if sys
import haxe.io.Path;
import lime.system.System;
import sys.db.Connection;
import sys.db.Sqlite;
#else
import flixel.util.FlxSave;
#end

// do custom flx save shit soon lol
class DatabaseManager
{
	public static var DatabasePath(default, null):String;
	public static var Connection(default, null):#if sys Connection #else FlxSave #end;
	private static final DBToLoad:Map<String, String> = ["keybinds" => "database.keybinds.KeybindsDBCache"];

	public static function Initialize()
	{
		FlxG.save.close();

		#if sys
		DatabasePath = Path.join([
			System.applicationStorageDirectory.replace("MyCompany", Application.current.meta.get("company"))
				.replace("MyApplication", Application.current.meta.get("file")),
			"engine.db"
		]);
		trace("Database opening at" + DatabasePath);
		Connection = Sqlite.open(DatabasePath);
		#else
		DatabasePath = '${Application.current.meta.get("company")}_${Application.current.meta.get("file")}';
		Connection = new FlxSave();
		trace("FlxSave binding to " + DatabasePath);
		Connection.bind(DatabasePath, "SanicBTW");
		#end

		for (key => classPath in DBToLoad)
		{
			trace("Loading " + key + " with class path " + classPath);
			final classRes:Class<Dynamic> = Type.resolveClass(classPath);

			if (classRes == null)
			{
				trace("Class " + key + " doesn't exist");
				continue;
			}

			cast(classRes, IDatabase).Load();
			trace("Loaded " + key);
		}
	}
}

interface IDatabase
{
	public function Load():Void;
	public function CreateTable():Void;
	public function Update<T>(update:T):Void;
	public function Delete<T>(delete:T):Void;
}
