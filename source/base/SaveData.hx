package base;

import base.system.DatabaseManager;

class SaveData
{
	public static var antialiasing:Bool = true;
	public static var showTrails:Bool = true;
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var onlyNotes:Bool = false;

	public static function getSettings():Array<String>
	{
		var returnArray:Array<String> = [];
		for (field in Type.getClassFields(SaveData))
		{
			if (Type.typeof(Reflect.field(SaveData, field)) != TFunction)
				returnArray.push(field);
		}
		return returnArray;
	}

	public static function saveSettings()
	{
		for (field in getSettings())
		{
			DatabaseManager.set(field, Reflect.field(SaveData, field));
		}

		DatabaseManager.set("ui_actions", Controls.uiActions);
		DatabaseManager.set("note_actions", Controls.noteActions);
		DatabaseManager.save();
	}

	public static function loadSettings()
	{
		for (field in getSettings())
		{
			var defaultValue:Dynamic = Reflect.field(SaveData, field);
			var save:Dynamic = DatabaseManager.get(field);
			Reflect.setField(SaveData, field, (save == null ? defaultValue : save));
		}

		if (DatabaseManager.get("ui_actions") == null)
		{
			trace("No UI Actions found on the save");
			DatabaseManager.set("ui_actions", Controls.uiActions);
		}

		if (DatabaseManager.get("note_actions") == null)
		{
			trace("No NOTE Actions found on the save");
			DatabaseManager.set("note_actions", Controls.noteActions);
		}

		Controls.reloadActions();
	}
}
