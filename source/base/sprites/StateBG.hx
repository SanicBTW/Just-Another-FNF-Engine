package base.sprites;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import openfl.display.BlendMode;

// Just a FlxSprite which loads the default bg with fallbacks applied
class StateBG extends FlxSpriteGroup
{
	var bg:FlxSprite;
	var opLayer:Null<FlxSprite>;

	public function new(opath:String)
	{
		super();

		// copycat for safety measures
		var path:String = opath;

		bg = new FlxSprite();

		var graphic:FlxGraphic = Paths.image('bgs/${Settings.bgTheme}/$path');
		if (graphic == null || path.indexOf("M") != -1)
		{
			if (graphic == null)
			{
				graphic = Paths.image('bgs/${Settings.bgTheme}/M_menuBG');
				path = opath + "M"; // force monochromatic when graphic is null
			}

			bg.blend = BlendMode.DIFFERENCE;
			bg.alpha = 0.2;
		}

		bg.loadGraphic(graphic);
		bg.setGraphicSize(flixel.FlxG.width, flixel.FlxG.height);
		bg.updateHitbox();

		if (path.indexOf("M") != -1)
		{
			opLayer = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.BLACK);
			opLayer.alpha = 0.7;
			opLayer.setGraphicSize(Std.int(bg.width));
			opLayer.updateHitbox();
			add(opLayer);
		}

		add(bg);

		this.screenCenter();
		active = false;
	}
}
