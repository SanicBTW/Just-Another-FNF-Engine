package base.system;

import flixel.FlxG;
import lime.app.Application;

using StringTools;

#if sys
import Type.ValueType;
import haxe.Json;
import haxe.io.Path;
import lime.system.System;
import sys.FileSystem;
import sys.io.File;
#end
#if html5
import js.Browser;
import js.html.Storage;
#end

class DatabaseManager
{
	public static var DatabasePath(default, null):String;
	public static var DB(default, null):#if sys Settings #else Storage #end;
	#if sys public static var TypeMap:Map<ValueType, String> = [TNull => "dynamic", TInt => "int", TFloat => "float", TBool => "bool"]; #end

	public static function Initialize()
	{
		FlxG.save.close();

		#if sys
		DatabasePath = Path.join([
			System.applicationStorageDirectory.replace("MyCompany", Application.current.meta.get("company"))
				.replace("MyApplication", Application.current.meta.get("file")),
			"engine.json"
		]);
		trace("Database opening at " + DatabasePath);
		DB = new Settings(DatabasePath);
		#end
		#if html5
		DatabasePath = '${Application.current.meta.get("company")}_${Application.current.meta.get("file")}.save';
		DB = Browser.getLocalStorage();
		trace("Local storage setting to " + DatabasePath);
		#end
	}

	// this method kind of sucks maybe something like DB.setItem(DatabasePath, "[key, value, type],[key, value, type]");
	public static function set(key:String, value:Null<String>)
	{
		trace('Setting $key with $value');
		#if html5
		DB.setItem('${key}_${DatabasePath}', '$value');
		#end
		#if sys
		DB.set(key, value);
		#end
	}

	public static function get #if sys <T> #end(key:String #if sys, retType:T #end):#if sys T #else Dynamic #end
	{
		trace('Getting $key');
		#if html5
		return DB.getItem('${key}_${DatabasePath}');
		#end
		#if sys
		return DB.get(retType, key);
		#end
	}

	public static function save()
	{
		#if sys
		DB.saveFile();
		#end
	}
}

#if sys
class Settings
{
	private var _path:String = "";
	private var _settings:Array<Setting> = [];

	public function new(path:String)
	{
		_path = path;

		if (!FileSystem.exists(path))
			File.saveContent(path, "");

		if (File.getContent(path).length > 0)
			_settings = cast Json.parse(File.getContent(path));
	}

	public function set(key:String, value:Dynamic)
	{
		if (_settings.length <= 0)
			_settings.push({name: key, value: value});

		for (setting in _settings)
		{
			if (setting.name == key)
			{
				trace("Key already exists, checking");
				if (setting.value != value)
				{
					trace("Existing key doesn't match new value");
					setting.value = value;
				}
				else
					trace("Existing key matches new value");
			}
			else
			{
				trace("Key doesn't exist pushing a new one");
				_settings.insert(_settings.length, {name: key, value: value});
			}
		}
	}

	public function get<T>(retType:T, key:String):T
	{
		for (setting in _settings)
		{
			if (setting.name == key)
				return setting.value;
		}
		return retType;
	}

	public function saveFile()
	{
		File.saveContent(_path, Json.stringify(_settings, null, "\t"));
	}
}

typedef Setting =
{
	var name:String;
	var value:Dynamic;
}
#end
