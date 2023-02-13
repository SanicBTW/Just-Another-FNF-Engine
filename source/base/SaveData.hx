package base;

import base.system.DatabaseManager;

class SaveData
{
	public static var antialiasing:Bool = true;

	public static function saveSettings()
	{
		for (field in Type.getClassFields(SaveData))
		{
			if (Type.typeof(Reflect.field(SaveData, field)) != TFunction)
			{
				DatabaseManager.set(field, Reflect.field(SaveData, field));
			}
		}
	}

	public static function loadSettings()
	{
		for (field in Type.getClassFields(SaveData))
		{
			if (Type.typeof(Reflect.field(SaveData, field)) != TFunction)
			{
				var defaultValue:Dynamic = Reflect.field(SaveData, field);
				var save:Dynamic = DatabaseManager.get(field);
				Reflect.setField(SaveData, field, (save != null ? save : defaultValue));
			}
		}
	}
}
