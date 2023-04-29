package;

import base.system.*;

class SaveData
{
	public static var framerate:Int = 60;
	public static var antialiasing:Bool = true;
	public static var showTrails:Bool = true;
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var onlyNotes:Bool = false;
	public static var pauseMusic:String = "tea-time";
	public static var language:String = "eng";

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
			SaveFile.set(field, Reflect.field(SaveData, field));
		}

		Controls.saveActions();
		Language.refresh();
		SaveFile.save();
	}

	public static function loadSettings()
	{
		for (field in getSettings())
		{
			var defaultValue:Dynamic = Reflect.field(SaveData, field);
			var save:Dynamic = SaveFile.get(field);
			Reflect.setProperty(SaveData, field, (save == null ? defaultValue : save));

			switch (field)
			{
				case "framerate":
					Main.setFPS(framerate);
			}
		}

		Controls.reloadActions();
	}
}
