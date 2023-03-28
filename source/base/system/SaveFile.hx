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
	private static var _save(default, null):FlxSave;

	public static var bound:Bool = false;

	public static function Initialize()
	{
		#if !debug
		FlxG.save.close();
		#end
		_save = new FlxSave();
		_save.bind("settings", #if (flixel < "5.0.0") Application.current.meta.get("company") #end);
		bound = true;
		SaveData.loadSettings();
	}

	public static inline function set(key:String, value:Dynamic)
	{
		Reflect.setField(_save.data, key, value);
	}

	public static inline function get(key:String):Dynamic
	{
		return Reflect.field(_save.data, key);
	}

	public static function save()
	{
		_save.flush(0, (_) ->
		{
			trace("Saved");
		});
	}
}
