package backend;

import lime.app.Application;

class Save
{
	private static var _db:SqliteKeyValue;

	public static function Initialize()
	{
		var version:Int = Std.parseInt(Application.current.meta.get("version").split(".")[1]);
		#if html5
		new SqliteKeyValue("JAFE:DB", "testing", 1).onConnect = (cock) ->
		{
			cock.set("niggers", "fr");
			cock.set("niggers2", "fr");
			cock.set("niggers3", "fr");
			cock.set("niggers4", "fr");

			cock.remove("niggers");
			cock.get("niggers2").then((res) ->
			{
				trace(res);
			});
			cock.get("niggers3").then((res) ->
			{
				trace(res);
			});
			cock.get("niggers4").then((res) ->
			{
				trace(res);
			});
		};
		#else
		_db = new SqliteKeyValue(haxe.io.Path.join([IO.getFolderPath(PARENT), "JAFE.db"]), "settings");
		#end
	}
}
