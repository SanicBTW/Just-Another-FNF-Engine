package base.ui;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;
import openfl.Assets;

class Fonts
{
	public static inline function VCR():FlxBitmapFont
		return Cache.getAtlas(Paths.getPath('VCR/VCR', "fonts"), BMFont);

	public static inline function Funkin():FlxBitmapFont
		return Cache.getAtlas(Paths.getPath('Funkin/Funkin', "fonts"), BMFont);

	public static function setProperties(text:FlxBitmapText, setBorder:Bool = true, targetSize:Float = 0.35)
	{
		if (setBorder)
			text.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);

		text.scrollFactor.set();
		text.autoSize = false;
		text.alignment = LEFT;
		text.fieldWidth = FlxG.width;
		text.antialiasing = SaveData.antialiasing;
		text.setGraphicSize(Std.int(text.width * targetSize));
		text.centerOrigin();
		text.updateHitbox();
	}
}
