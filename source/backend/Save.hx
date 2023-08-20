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
		}).future.onComplete((newDB) ->
			{
				_db = newDB;
				loadSettings();
				loadQuaver();
				lime.app.Application.current.window.title = "Just Another FNF Engine";
			});
	}

	@:noCompletion
	private static function loadSettings()
	{
		lime.app.Application.current.window.title = "Loading settings!";
		var settings:Array<String> = Type.getClassFields(Settings);

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

	@:noCompletion
	private static function loadQuaver()
	{
		// Converting all of the existing beatmaps is probably the best option to avoid having numbers and shit
		lime.app.Application.current.window.title = "Loading QuaverDB! (Expensive)";
		for (MapSetId => MapIds in quaver.QuaverDB.availableMaps)
		{
			for (MapId in MapIds)
			{
				#if html5
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
				#else
				var map:quaver.Qua = _db.get("quaverDB", MapId);
				if (map == null)
				{
					// DO NOT PARSE HIT OBJECTS ON FIRST RUN, Audio will be converted automatically on non HTML5 platforms
					map = new quaver.Qua(Cache.getText(Paths.file('quaver/$MapSetId/$MapId.qua')), false);
					_db.set("quaverDB", MapId, map);
				}

				quaver.QuaverDB.loadedMaps.set('${map.MapId}', map);
				#end
			}
		}
	}
}
