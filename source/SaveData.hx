package;

import base.system.Controls;
import base.system.SaveFile;
import flixel.FlxG;

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
			SaveFile.set(field, Reflect.field(SaveData, field));
		}

		SaveFile.set('volume', FlxG.sound.volume);
		SaveFile.set('mute', FlxG.sound.muted);

		Controls.saveActions();

		SaveFile.save();
	}

	public static function loadSettings()
	{
		for (field in getSettings())
		{
			var defaultValue:Dynamic = Reflect.field(SaveData, field);
			var save:Dynamic = SaveFile.get(field);
			Reflect.setField(SaveData, field, (save == null ? defaultValue : save));
		}

		/* the fuck, this shit giving me null object reference, like BRO YOU ARE IN AN IF STATEMENT THAT CHECKS IF YOU ARE NULL 
				if (SaveFile.get("volume") != null)
					FlxG.sound.volume = SaveFile.get("volume"); 

			if (SaveFile.get("mute") != null)
				FlxG.sound.muted = SaveFile.get("mute"); */

		Controls.reloadActions();
	}
}
