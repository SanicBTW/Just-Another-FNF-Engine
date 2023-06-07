package funkin;

import backend.IO;
import backend.ScriptHandler;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

/*So my old implementation on psych was based off Lullaby's system https://github.com/SanicBTW/FNF-PsychEngine-0.3.2h/blob/hxs-forever/source/hxs/Events.hx
	I will be mixing it with the Hybrid method https://github.com/SanicBTW/Forever-Engine-Archive/blob/hybrid/source/base/Events.hx 
	Get files filtering folder (Paths.getLibraryFile(TEXT, 'events'))
 */
class Events
{
	public static var eventList:Array<String> = [];
	public static var loadedModules:Map<String, ForeverModule> = [];

	public static function obtainEvents()
	{
		loadedModules.clear();
		eventList = IO.getFolderFiles(EVENTS);
		if (eventList == null)
			eventList = [];

		if (eventList.length > 0)
		{
			for (i in 0...eventList.length)
			{
				eventList[i] = eventList[i].substring(0, eventList[i].indexOf('.', 0));
				loadedModules.set(eventList[i], ScriptHandler.loadModule(eventList[i], 'events'));
			}
			eventList.sort(function(a, b) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));
		}
		eventList.insert(0, '');
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
