package base.system;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSignal.FlxTypedSignal;
import lime.app.Application;

// will be deleted on next commit
class Scroll
{
	public static var CROCHET:FlxSprite;
	public static var POSITION(default, null):Float = 0;
	public static var SPEED:Float = 0;
	public static var ON_UPDATE(default, null):FlxTypedSignal<Float->Void> = new FlxTypedSignal<Float->Void>();
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
		ON_UPDATE.removeAll();
	}

	private static function updatePos(_)
	{
		// bpm / 100 or position / speed or position * speed or literally set the speed to bpm / 100
		POSITION += FlxG.elapsed * Conductor.stepCrochet;
		ON_UPDATE.dispatch(FlxG.elapsed);
	}
}

enum abstract ScrollDirection(Int) to Int
{
	var UP = 1;
	var DOWN = -1;
}
