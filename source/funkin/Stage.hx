package funkin;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.Json;
import openfl.Assets;

using StringTools;

typedef StageFile =
{
	var properties:StageProperties;
	var objects:Array<StageObject>;
}

// Psych shit
typedef StageProperties =
{
	var defaultZoom:Float;
}

// Last minute idea lol - thanks to Galo for likin it
typedef StageObject =
{
	var name:String;
	var graphicPath:String;
}

class Stage extends FlxTypedGroup<FlxBasic>
{
	public var cameraZoom:Float = 1;

	public function new(stage:String)
	{
		super();

		var rawStage:String = Assets.getText(Paths.getPath('stages/$stage.json')).trim();
		var stageJSON:StageFile = cast Json.parse(rawStage);

		cameraZoom = stageJSON.properties.defaultZoom;

		trace(stageJSON);

		for (object in stageJSON.objects)
		{
			Reflect.setField(this, object.name, new FlxSprite());
			if (Reflect.field(this, object.name) != null)
			{
				trace("Field doesn't seem to be null");
				var newSprite:FlxSprite = cast(Reflect.getProperty(this, object.name), FlxSprite);
				newSprite.loadGraphic(Paths.image(object.graphicPath));
				add(newSprite);
			}
		}
	}
}
