package backend;

class Save
{
	private static var _db:SqliteKeyValue;

	public static function Initialize()
	{
		#if html5
		// Re-assign though it won't be really useful

		new SqliteKeyValue("JAFE:DB", ["settings", "highscores"],
			Std.parseInt(lime.app.Application.current.meta.get("version").split(".")[1])).onConnect = (res) ->
			{
				_db = res;

				loadSettings();
			};
		#else
		_db = new SqliteKeyValue(haxe.io.Path.join([IO.getFolderPath(PARENT), "JAFE.db"]), ["settings", "highscores"]);

		loadSettings();
		#end
	}

	@:noCompletion
	private static function loadSettings()
	{
		var settings:Array<String> = Type.getClassFields(Settings);
		trace(settings);

		// because promises exist (i fucking hate them so much ong), once i make sys sql promise based it will be the same for all targets hopefully
		for (field in settings)
		{
			#if html5
			var defaultValue:Any = Reflect.field(Settings, field);
			_db.get("settings", field).then((save:Any) ->
			{
				if (save == null)
				{
					_db.set("settings", field, defaultValue);
					save = defaultValue;
				}

				Reflect.setField(Settings, field, save);
			});
			#else
			var defaultValue:Any = Reflect.field(Settings, field);
			var save:Any = _db.get("settings", field);
			if (save == null)
			{
				_db.set("settings", field, defaultValue);
				save = defaultValue; // god im so dumb - override gotten value with the default one as its null and default value isnt
			}

			Reflect.setField(Settings, field, save);
			#end
		}
	}
}
