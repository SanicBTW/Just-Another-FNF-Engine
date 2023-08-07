package backend;

class Save
{
	private static var _db:SqliteKeyValue;

	public static function Initialize()
	{
		var settings:Array<String> = Type.getClassFields(Settings);
		trace(settings);

		#if html5
		// Re-assign though it won't be really useful

		new SqliteKeyValue("JAFE:Settings", "settings", Std.parseInt(lime.app.Application.current.meta.get("version").split(".")[1])).onConnect = (res) ->
		{
			_db = res;
			trace('Connected to JAFE:Settings');
		};
		#else
		_db = new SqliteKeyValue(haxe.io.Path.join([IO.getFolderPath(PARENT), "JAFE.db"]), "settings");
		_db.createTable("highscores");

		// Loads the settings
		for (field in settings)
		{
			var defaultValue:Any = Reflect.field(Settings, field);
			var save:Any = _db.get("settings", field);
			if (save == null)
			{
				_db.set("settings", field, defaultValue);
				save = defaultValue; // god im so dumb - override gotten value with the default one as its null and default value isnt
			}

			Reflect.setField(Settings, field, save);
		}
		#end
	}
}
