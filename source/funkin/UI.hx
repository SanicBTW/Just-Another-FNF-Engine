package funkin;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import haxe.Json;
import openfl.utils.Assets;

using StringTools;

typedef UIComponent =
{
	var classPath:String;
	var classArgs:Array<String>;
	var name:String;
	var positions:Array<Dynamic>;

	// Optional vars, depending on the type it might be needed
	@:optional var use_defaults:Bool;
	@:optional var text:String;
}

class UI extends FlxSpriteGroup
{
	private var objectStore:Map<String, FlxSprite> = [];

	public function new(player:Character, opponent:Character)
	{
		super();

		var rawUI:String = Assets.getText(Paths.getPreloadPath('data/UI_Layout.json')).trim();
		var uiJSON:{components:Array<UIComponent>} = cast Json.parse(rawUI);

		for (component in uiJSON.components)
		{
			// totally extends an flx sprite fr
			objectStore.set(component.name, Type.createInstance(Type.resolveClass(component.classPath), component.classArgs));
			var newComp:FlxSprite = objectStore.get(component.name);
			add(newComp);
		}
	}

	public function updateText() {}

	private function resolve(text:String) {}
}
