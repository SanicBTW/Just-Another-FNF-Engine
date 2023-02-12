package base.system;

import Type.ValueType;
import base.system.database.keybinds.KeybindsDBCache;
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
	public static var TypeMap:Map<ValueType, String> = [TNull => "TEXT", TInt => "INTEGER", TFloat => "FLOAT", TBool => "BIT"];

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
		DatabasePath = '${Application.current.meta.get("company")}_${Application.current.meta.get("file")}';
		Connection = new FlxSave();
		trace("FlxSave binding to " + DatabasePath);
		Connection.bind(DatabasePath, "SanicBTW");
		#end

		KeybindsDBCache.Initialize();
	}

	public static function createTable<T>(t:Class<T>, id:Null<Int>)
	{
		var instance:T = Type.createInstance(t, []);
		// Type.getClassName(t); base.system.database.keybinds.Keybinds
		// schema of folders is like base[0].system[1].database[2](parent2).db[3](parent).cache/db setup stuff[4]
		var className:String = Type.getClassName(t).split(".")[3];
		var classFields:Array<String> = Type.getInstanceFields(t);
		var append:String = "";
		for (field in classFields)
		{
			append += transform(instance, field);
		}
		var s:StringBuf = new StringBuf();
		s.add('CREATE TABLE IF NOT EXISTS ${className}(
				id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
				${append}
			)');
		Connection.addValue(s, id);
		trace("Created table (Table name " + className + ", fields/columns? " + classFields + " )");
	}

	public static function transform<T>(t:T, field:String):String
	{
		var type:String = TypeMap.get(Type.typeof(Reflect.field(t, field)));
		return '${field} ${type}\r\n';
	}

	public static function createString(string:String):StringBuf
	{
		var stringBuf:StringBuf = new StringBuf();
		stringBuf.add(string);
		return stringBuf;
	}
}
