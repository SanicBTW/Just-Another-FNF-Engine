package base.system.database.keybinds;

import sys.db.ResultSet;

class Keybinds
{
	public var action:String;
	public var actionGroup:String;
	public var keyCode:Int;

	public function new() {}
}

class KeybindsDBCache
{
	public static function Initialize():Void
	{
		CreateTable();
	}

	public static function CreateTable():Void
	{
		try
		{
			DatabaseManager.createTable(Keybinds, 0);
		}
		catch (e)
		{
			throw e;
		}
	}
}
