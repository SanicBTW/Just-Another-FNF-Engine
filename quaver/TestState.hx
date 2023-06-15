package;

import backend.Controls;
import backend.IsolatedPaths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import network.Request;
import network.pocketbase.User;

class TestState extends FlxState
{
	var controls:Controls = new Controls();
	var paths:IsolatedPaths = new IsolatedPaths('quaver');
	var sex:FlxSprite;
	var gfsex:FlxSprite;

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

		var user = new User({identity: 'sanco', password: ''});

		new Request('https://storage.sancopublic.com/gfDanceTitle.xml', (xmlshit:String) ->
		{
			new Request('https://storage.sancopublic.com/gfDanceTitle.png', (gfbooby:FlxGraphic) ->
			{
				gfsex = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
				gfsex.frames = FlxAtlasFrames.fromSparrow(gfbooby, xmlshit);
				gfsex.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				gfsex.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				gfsex.animation.play('danceLeft');
				gfsex.antialiasing = true;
				gfsex.animation.finishCallback = (ani:String) ->
				{
					if (ani == 'danceLeft')
						gfsex.animation.play('danceRight');
					else
						gfsex.animation.play('danceLeft');
				};
				add(gfsex);
			}, IMAGE);
		}, RAW_STRING);

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
