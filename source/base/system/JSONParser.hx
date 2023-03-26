package base.system;

import haxe.Json;

using StringTools;

// Made to make JSON File parsing more extensive and not copy pasted for each module
@:generic
class JSONParser<T>
{
	public function new(rawString:String)
	{
		var json:T = cast Json.parse(rawString);
	}
}
