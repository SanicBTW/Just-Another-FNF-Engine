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
	private static var _saveMap(default, null):Map<Save, FlxSave> = [DEFAULT => new FlxSave(), UI_LAYOUT => new FlxSave(), KEYBINDS => new FlxSave()];

	public static var bound:Bool = false;

	public static function Initialize()
	{
		#if !debug
		FlxG.save.close();
		#end

		// Siguiendo tus pasos Galo *procede a abrir 500 FlxSaves*
		for (key => save in _saveMap)
		{
			// Fuck you Flixel
			save.bind(key, Application.current.meta.get("company"));
		}

		bound = true;
		SaveData.loadSettings();
	}

	public static function set(key:String, value:Dynamic, save:Save = DEFAULT)
	{
		Reflect.setField(_saveMap.get(save).data, key, value);
	}

	public static function get(key:String, save:Save = DEFAULT):Dynamic
	{
		return Reflect.field(_saveMap.get(save).data, key);
	}

	public static function save()
	{
		for (key => save in _saveMap)
		{
			// Fuck you Flixel
			save.flush(0, (success) ->
			{
				trace('Saved $key ($success)');
			});
		}
	}
}

// Holds the save name to bind it on FlxSave lol
// I would've liked using Reflect :sob:
enum abstract Save(String) to String
{
	var DEFAULT = "settings";
	var UI_LAYOUT = "ui_layout";
	var KEYBINDS = "keybinds";
}
