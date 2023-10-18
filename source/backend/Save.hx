package backend;

class Save
{
	private static var _db:SqliteKeyValue;
	public static var shouldLoadQuaver:Bool = true; // temp fix to avoid loading quaver beatmapps always

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
				loadKeybinds();
				if (shouldLoadQuaver)
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
	private static function loadKeybinds()
	{
		@:privateAccess
		{
			var keys = Controls.actions.keys();
			for (key in keys)
			{
				var defKeys:Null<Array<Null<Int>>> = Controls.actions.get(key);
				var fkey:String = Std.string(key);

				_db.get('keybinds', fkey).then((save:Any) ->
				{
					if (save == null)
					{
						_db.set('keybinds', fkey, defKeys);
						save = defKeys;
					}

					Reflect.setProperty(Reflect.getProperty(flixel.FlxG.state.controls, fkey), 'keys', save);
				});
			}
		}
	}

	@:noCompletion
	private static function loadQuaver()
	{
		// TODO: find a way to not parse all the beatmaps and shit on startup
		// Converting all of the existing beatmaps is probably the best option to avoid having numbers and shit
		Paths.changeLibrary(QUAVER, (lib) ->
		{
			var unfiltered:Array<String> = lib.list("TEXT"); // Only target .qua files cuz we only need em

			var maps:Map<String, Array<String>> = new Map();
			for (entry in unfiltered)
			{
				var raw:String = entry.substring(0, entry.lastIndexOf("/")); // lil helper :skull:

				var MapSetId:String = raw.substring(raw.lastIndexOf("/") + 1);
				if (maps.get(MapSetId) == null)
					maps.set(MapSetId, []);

				// if value greater than -1 it means it was found
				if (entry.indexOf(MapSetId) > -1)
				{
					raw = entry;

					var MapId:String = backend.io.Path.withoutDirectory(backend.io.Path.withoutExtension(raw));
					maps.get(MapSetId).push(MapId);
				}
			}
			quaver.QuaverDB.availableMaps = maps; // copycat for safety purposes

			for (MapSetId => MapIds in quaver.QuaverDB.availableMaps)
			{
				for (MapId in MapIds)
				{
					_db.get("quaverDB", MapId).then((savedM:Any) ->
					{
						var map:quaver.Qua = cast savedM;
						if (map == null)
						{
							map = new quaver.Qua(Cache.getText(Paths.file('$MapSetId/$MapId.qua')), false);
							_db.set("quaverDB", MapId, map);
						}

						quaver.QuaverDB.loadedMaps.set('${map.MapId}', map);
					});
				}
			}
		});

		// Unload folder for memory purposes???? (HTML5 needs it tho, yeah idrc you can load it again when opening the selection state so yeah, windows doesnt need it cuz the song file is converted to ogg and saved locally)
		openfl.utils.Assets.unloadLibrary(Paths.Libraries.QUAVER);
	}
}
