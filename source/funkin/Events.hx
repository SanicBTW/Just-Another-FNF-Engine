package funkin;

import backend.ScriptHandler;
import haxe.io.Path;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Events
{
	private static var eventList:Array<String> = [];
	public static var loadedModules:Map<String, ForeverModule> = [];

	public static function addEvent(event:String):Bool
	{
		if (eventList.length < 0)
			return false;

		for (eventPath in eventList)
		{
			if (StringTools.contains(eventPath, event))
			{
				loadedModules.set(event, ScriptHandler.loadModule(Path.withoutExtension(eventPath), 'events'));
				return true;
			}
		}

		eventList.sort(function(a, b) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));
		return false;
	}

	public static function returnDescription(event:String):String
	{
		if (loadedModules.get(event) != null)
		{
			var module:ForeverModule = loadedModules.get(event);
			if (module.exists('returnDescription'))
				return module.get('returnDescription')();
		}
		return '';
	}
}
