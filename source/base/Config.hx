package base;

class Config
{
	public static var firstTime:Bool = true;

	public static function loadSettings()
	{
		for (field in Type.getClassFields(Config))
		{
			if (Type.typeof(Reflect.field(Config, field)) != TFunction)
			{
				trace(field);
			}
		}
	}
}
