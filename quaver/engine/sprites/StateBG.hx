package engine.sprites;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import openfl.display.BlendMode;

// Just a FlxSprite which loads the default bg with fallbacks applied
class StateBG extends FlxSpriteGroup
{
	var bg:FlxSprite;
	var opLayer:FlxSprite;

	public function new(path:String)
	{
		super();

		bg = new FlxSprite();

		opLayer = new FlxSprite();
		opLayer.alpha = 0.7;

		var graphic:FlxGraphic = Paths.image('bgs/${Settings.bgTheme}/$path');
		if (graphic == null || path.indexOf("M") != -1)
		{
			if (graphic == null)
				graphic = Paths.image('bgs/${Settings.bgTheme}/M_menuBG');

			bg.blend = BlendMode.DIFFERENCE;
			bg.alpha = 0.2;
		}

		bg.loadGraphic(graphic);
		bg.setGraphicSize(flixel.FlxG.width);

		if (path.indexOf("M") != -1)
		{
			opLayer.setGraphicSize(Std.int(bg.width));
			add(opLayer);
		}

		add(bg);
	}
}
