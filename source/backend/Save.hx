package backend;

class Save
{
	private static var _db:SqliteKeyValue;

	public static function Initialize()
	{
		new SqliteKeyValue({
			path: #if html5 "JAFE:DB" #else backend.io.Path.join(IO.getFolderPath(PARENT), "JAFE.db") #end,
			tables: ["settings", "keybinds", "highscores", "quaverDB"],
			version: Std.parseInt(lime.app.Application.current.meta.get("version")
				.split(".")[1]) // Because this param isn't used on sys, it uses the html5 one instead
		}).then((newDB) ->
			{
				_db = newDB;
				loadSettings();
				loadQuaver();
			});
	}

	@:noCompletion
	private static function loadSettings()
	{
		var settings:Array<String> = Type.getClassFields(Settings);

		for (field in settings)
		{
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
		}
	}

	@:noCompletion
	private static function loadQuaver()
	{
		// Converting all of the existing beatmaps is probably the best option to avoid having numbers and shit
		for (MapSetId => MapIds in quaver.QuaverDB.availableMaps)
		{
			for (MapId in MapIds)
			{
				_db.get("quaverDB", MapId).then((savedM:Any) ->
				{
					var map:quaver.Qua = cast savedM;
					if (map == null)
					{
						map = new quaver.Qua(Cache.getText(Paths.file('quaver/$MapSetId/$MapId.qua')), false);
						_db.set("quaverDB", MapId, map);
					}

					quaver.QuaverDB.loadedMaps.set('${map.MapId}', map);
				});
			}
		}
	}
}
