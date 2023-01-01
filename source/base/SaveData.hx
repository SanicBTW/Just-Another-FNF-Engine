package base;

class SaveData
{
	public static var antialiasing:Bool = true;

	public static function saveSettings()
	{
		for (field in Type.getClassFields(SaveData))
		{
			if (Type.typeof(Reflect.field(SaveData, field)) != TFunction)
			{
				Reflect.setField(flixel.FlxG.save.data, field, Reflect.field(SaveData, field));
			}
		}
		flixel.FlxG.save.flush();
	}

	public static function loadSettings()
	{
		for (field in Type.getClassFields(SaveData))
		{
			if (Type.typeof(Reflect.field(SaveData, field)) != TFunction)
			{
				var defaultValue:Dynamic = Reflect.field(SaveData, field);
				var flxProp:Dynamic = Reflect.field(flixel.FlxG.save.data, field);
				Reflect.setField(SaveData, field, (flxProp != null ? flxProp : defaultValue));
			}
		}
	}
}
