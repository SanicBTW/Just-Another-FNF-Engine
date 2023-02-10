package funkin;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.DynamicAccess;
import haxe.Json;
import openfl.Assets;

using StringTools;

typedef StageFile =
{
	var defaultZoom:Float;
	var objects:Array<Dynamic>;
}

class Stage extends FlxTypedGroup<FlxBasic>
{
	public var cameraZoom:Float = 1;

	private var objectMap:Map<String, FlxSprite> = [];

	public function new(stage:String)
	{
		super();

		var rawStage:String = Assets.getText(Paths.getPreloadPath('stages/$stage.json')).trim();
		var stageJSON:StageFile = cast Json.parse(rawStage);

		cameraZoom = stageJSON.defaultZoom;

		for (object in stageJSON.objects)
		{
			var newSprite:FlxSprite = Type.createInstance(FlxSprite, [0, 0]);
			var stageObject = new StageObject(object, newSprite, objectMap);
			newSprite.updateHitbox();
			add(newSprite);
		}
	}
}

class StageObject
{
	public function new(object:Dynamic, sprite:FlxSprite, spriteMap:Map<String, FlxSprite>)
	{
		spriteMap.set(object.name, sprite);

		var shit:DynamicAccess<Dynamic> = object;

		for (prop => value in shit)
		{
			switch (prop)
			{
				case "name":
					continue;
				case "graphic":
					sprite.loadGraphic(Paths.image(value));
				case "size":
					{
						sprite.setGraphicSize(Std.int(parse(value[0], spriteMap)));
						if (value[1] != null)
							sprite.setGraphicSize(Std.int(parse(value[0], spriteMap)), Std.int(parse(value[1], spriteMap)));
					}
				case "position":
					{
						sprite.setPosition(Std.parseFloat(parse(value[0], spriteMap)), Std.parseFloat(parse(value[1], spriteMap)));
					}
				case "scroll_factor":
					{
						sprite.scrollFactor.set(value[0], value[1]);
					}
				default:
					{
						if (Reflect.field(sprite, prop) != null)
							Reflect.setField(sprite, prop, value);
						else
							trace('Stage JSON tried to access $prop but it doesn\'t exist');
					}
			}
		}
	}

	private function parse(string:Dynamic, spriteMap:Map<String, FlxSprite>):Dynamic
	{
		var stdString:String = Std.string(string);
		var functionName:String = stdString.substring(0, stdString.indexOf("(", 0)).trim();
		var functionArgs:Array<String> = stdString.substring(stdString.indexOf("(", 0) + 1, stdString.indexOf(")", 0)).split(",");
		var functionPost:Array<String> = stdString.substring(stdString.indexOf(")", 0) + 1, stdString.length).split(" ");

		// remove if there is a space
		if (functionPost[0] == "")
			functionPost.splice(0, 1);

		if (functionName == "")
			return string;

		switch (functionName)
		{
			default:
				trace('$functionName not recognized');
			case "getObj":
				var object:String = functionArgs[0].trim();
				var property:String = functionArgs[1].trim();
				if (spriteMap.exists(object))
					return doPost(functionPost, Reflect.field(spriteMap.get(object), property));
				else
					trace('${functionArgs[0]} not found on sprite map');
		}

		return string;
	}

	private function doPost(args:Array<String>, value:Dynamic)
	{
		switch (args[0])
		{
			default:
				trace('${args[0]} not recognized');
			case "*":
				{
					var parsedArg:Float = Std.parseFloat(args[1]);
					var parsedVal:Float = Std.parseFloat(value);
					return parsedVal * parsedArg;
				}
		}

		return value;
	}
}
