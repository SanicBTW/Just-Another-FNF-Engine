package backend;

import database.IDatabase.DBBackend;

class Save
{
	public static var database:DBBackend;
	public static var shouldLoadQuaver:Bool = true; // temp fix to avoid loading quaver beatmaps always

	public static function Initialize()
	{
		var dbConnect:SPromise<DBBackend> = new DBBackend({
			path: #if html5 "JAFE:DB" #else backend.io.Path.join(IO.getFolderPath(PARENT), "JAFE.db") #end,
			tables: [SETTINGS, BINDS, HIGHSCORES, QUAVER_DB, VFS],
			version: Std.parseInt(lime.app.Application.current.meta.get("version")
				.split(".")[0]) // Because this param isn't used on sys, it uses the html5 one instead
		}).connect();

		dbConnect.then((newDB) ->
		{
			database = newDB;
			trace("Successfully connected to the Database Backend");
			loadSettings();
			reloadKeybinds();
			if (shouldLoadQuaver)
				loadQuaver();
		});

		dbConnect.catchError((err) ->
		{
			trace('Failed to connect to the Database Backend: $err');
		});
	}

	@:noCompletion
	private static function loadSettings()
	{
		var settings:Array<String> = Type.getClassFields(Settings);

		for (field in settings)
		{
			var defaultValue:Any = Reflect.field(Settings, field);
			database.get(SETTINGS, field).then((save:Any) ->
			{
				if (save == null)
				{
					database.set(SETTINGS, field, defaultValue);
					save = defaultValue;
				}

				Reflect.setField(Settings, field, save);
			});
		}
	}

	@:noCompletion
	private static function reloadKeybinds() // I think it works on both ways, when saving and when loading cuz when loading it takes up the default binds and when saving it gets the modified binds (cuz we directly modify the action map) and this accesses the action map
	{
		var endMap:haxe.ds.DynamicMap<backend.input.Controls.ActionType, backend.input.Controls.SavedAction> = new haxe.ds.DynamicMap();

		// I don't want to cook a macro for nothing (I ain't workin on macros ever again bruh and even worse if its working with enums)
		var actions:Array<backend.input.Controls.ActionType> = [
			CONFIRM, BACK, RESET, PAUSE, UI_LEFT, UI_DOWN, UI_UP, UI_RIGHT, NOTE_LEFT, NOTE_DOWN, NOTE_UP, NOTE_RIGHT
		];

		@:privateAccess
		{
			for (action in actions)
			{
				// 100% sure that ain't null ong
				endMap[action] = {
					kbBinds: backend.input.Keyboard.actions.get(action),
					gpBinds: backend.input.Controller.actions.get(action)
				};

				database.get(BINDS, Std.string(action)).then((save:Any) ->
				{
					if (save == null)
					{
						database.set(BINDS, Std.string(action), endMap[action]);
						save = endMap[action];
						#if debug
						trace('Saved binds on $action not found');
						#end
					}

					var binds:backend.input.Controls.SavedAction = save;
					backend.input.Keyboard.actions.set(action, binds.kbBinds);
					backend.input.Controller.actions.set(action, binds.gpBinds);
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
					database.get(QUAVER_DB, MapId).then((savedM:Any) ->
					{
						var map:quaver.Qua = cast savedM;
						if (map == null)
						{
							map = new quaver.Qua(Cache.getText(Paths.file('$MapSetId/$MapId.qua')), false);
							database.set(QUAVER_DB, MapId, map);
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
