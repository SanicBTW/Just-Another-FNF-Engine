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
		DatabaseManager.save();
	}

	public static function loadSettings()
	{
		for (field in Type.getClassFields(SaveData))
		{
			if (Type.typeof(Reflect.field(SaveData, field)) != TFunction)
			{
				var defaultValue:Dynamic = Reflect.field(SaveData, field);

				var save = DatabaseManager.get(field #if sys, DatabaseManager.TypeMap.get(Type.typeof(Reflect.field(SaveData, field))) #end);
				trace(Type.typeof(save));
				// Reflect.setField(SaveData, field, (save != null ? save : defaultValue));
			}
		}
	}
}
