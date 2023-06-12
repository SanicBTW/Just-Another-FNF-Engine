package;

import backend.Controls;
import backend.IsolatedPaths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;

class TestState extends FlxState
{
	var controls:Controls = new Controls();
	var paths:IsolatedPaths = new IsolatedPaths('quaver');
	var sex:FlxSprite;

	override function create()
	{
		sex = new FlxSprite(0, 0);
		sex.frames = paths.getSparrowAtlas('SMOOTH_NOTE_assets');
		sex.animation.addByPrefix('static', 'arrowDOWN', 60, false);
		sex.animation.addByPrefix('pressed', 'down press', 60, false);
		sex.animation.addByPrefix('confirm', 'down confirm', 60, false);
		sex.screenCenter();
		sex.antialiasing = true;
		add(sex);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.confirm.state == PRESSED)
		{
			if (sex.animation.curAnim.name != "confirm")
				sex.animation.play('confirm');
		}
		else
			sex.animation.play('static');

		super.update(elapsed);
	}
}
