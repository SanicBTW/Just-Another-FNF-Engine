package funkin.ui;

import base.system.JSONAnalyzer;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import haxe.DynamicAccess;
import haxe.Json;
import openfl.Assets;

using StringTools;

typedef UIELementAttributes =
{
	var name:String;
	var type:String;
	var tracks:String;
	var parse:Array<String>;
	var position:Array<Float>;
}

class UI extends FlxSpriteGroup
{
	private var objectMap:Map<String, FlxSprite> = [];

	public function new(skin:String)
	{
		super();

		var rawSkin:String = Assets.getText(Paths.getPreloadPath('ui_skin/$skin.json')).trim();
		var skinJSON:Array<UIELementAttributes> = cast Json.parse(rawSkin);

		for (element in skinJSON)
		{
			for (parse in element.parse) {}
		}
	}
}
