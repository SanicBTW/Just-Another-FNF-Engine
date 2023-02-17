package base.system;

import flixel.FlxG;
import flixel.util.FlxSave;
import lime.app.Application;

using StringTools;

// just manages save shit lol
class DatabaseManager
{
	private static var _save(default, null):FlxSave;

	public static function Initialize()
	{
		// FlxG.save.close();

		_save = new FlxSave();
		_save.bind("db", null);
		SaveData.loadSettings();
	}

	public static inline function set(key:String, value:Dynamic)
		Reflect.setField(_save.data, key, value);

	public static inline function get(key:String):Dynamic
		return Reflect.field(_save.data, key);

	public static function save()
	{
		_save.flush(0, (_) ->
		{
			trace("Saved");
		});
	}
}
