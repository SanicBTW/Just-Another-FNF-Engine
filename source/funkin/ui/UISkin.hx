package funkin.ui;

import base.system.JSONAnalyzer;
import haxe.DynamicAccess;
import haxe.Json;
import openfl.Assets;

using StringTools;

typedef UIFile =
{
	var accuracy:UIELementAttributes;
}

typedef UIELementAttributes =
{
	var position:Array<Float>;
}

class UISkin
{
	public function new(skin:String)
	{
		var rawSkin:String = Assets.getText(Paths.getPreloadPath('ui_skin/$skin.json')).trim();
		var skinJSON:UIFile = cast Json.parse(rawSkin);

		// var ana:JSONAnalyzer<UIELementAttributes> = new JSONAnalyzer(skinJSON);
	}
}
