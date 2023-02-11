package base.system.database.keybinds;

import base.system.DatabaseManager.IDatabase;

class KeybindsDBCache implements IDatabase
{
	public function CreateTable():Void
	{
		try
		{
			DatabaseManager.Connection.addValue("Keybinds", {"ui_up" => ""});
		}
	}
}
