package funkin.components;

import base.sprites.RoundSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.states.options.OptionsState;

// Not exactly a component but its used in settings so uhhhh yeah
class SidebarItem extends FlxSpriteGroup
{
	private var _bg:RoundSprite;
	private var _text:FlxText;

	// isFirst rounds the element to match the list
	// isEnd rounds the element to match the list
	public function new(parent:Sidebar, name:String, isFirst:Bool = false, isEnd:Bool = false)
	{
		super();

		var cornerRad:Array<Float> = [0];
		if (isFirst)
			cornerRad = [15, 15, 0, 0];
		if (isEnd)
			cornerRad = [0, 0, 15, 15];

		_bg = new RoundSprite(parent._bg.x, (parent._header.y + parent._header.fieldHeight) + (OptionsState.margin - 5), parent._bg.shapeWidth, 50, cornerRad,
			FlxColor.WHITE);
		_bg.alpha = 0.8;

		_text = new FlxText(_bg.x + 5, _bg.y + 15, 0, name, 20);
		_text.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.BLACK, LEFT);

		add(_bg);
		add(_text);
	}
}
