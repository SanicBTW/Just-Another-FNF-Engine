package base.system;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import lime.app.Application;

class Scroll
{
	public static var CROCHET:FlxSprite;
	public static var POSITION(default, null):Float = 0;
	private static var DIRECTION(default, null):ScrollDirection = (SaveData.downScroll ? DOWN : UP);

	public static function init()
	{
		if (CROCHET == null)
			CROCHET = new FlxSprite(FlxG.width / 2, (DIRECTION == -1 ? FlxG.height - 150 : 60)).makeGraphic(Std.int(FlxG.width / 2), 10, FlxColor.WHITE, true);
		Application.current.onUpdate.add(updatePos);
	}

	public static function stop()
	{
		Application.current.onUpdate.remove(updatePos);
	}

	private static function updatePos(_)
	{
		POSITION += FlxG.elapsed * 1000;
	}
}

enum abstract ScrollDirection(Int) to Int
{
	var UP = 1;
	var DOWN = -1;
}
