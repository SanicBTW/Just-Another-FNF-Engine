package;

import backend.Controls;
import backend.IsolatedPaths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class TestState extends FlxState
{
	var controls:Controls = new Controls();
	var paths:IsolatedPaths = new IsolatedPaths('quaver');
	var sex:FlxSprite;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.WHITE;
		sex = new FlxSprite(0, 0);

		sex.frames = paths.getSparrowAtlas('LITE_NOTE_assets');
		sex.setGraphicSize(Std.int(sex.frameWidth * 0.7));
		sex.animation.addByIndices('static', 'staticBlue', [0], '', 24, false);
		sex.animation.addByIndices('pressed', 'staticBlue', [1], '', 24, false);
		sex.animation.addByIndices('confirm', 'staticBlue', [2], '', 24, false);

		sex.screenCenter();
		sex.antialiasing = true;
		add(sex);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.confirm.state == PRESSED)
		{
			if (sex.animation.curAnim.name != "pressed")
			{
				sex.animation.play('pressed');
			}
		}
		else
			sex.animation.play('static');

		if (controls.reset.state == PRESSED)
		{
			Main.cock.screenCenter();
			trace('centring');
		}

		super.update(elapsed);
	}
}
