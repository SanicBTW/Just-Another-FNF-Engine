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
		return FlxBitmapFont.fromAngelCode(getGraphic("VCR"), getCode("VCR"));

	public static inline function Funkin():FlxBitmapFont
		return FlxBitmapFont.fromAngelCode(getGraphic("Funkin"), getCode("Funkin"));

	private static function getGraphic(fontName:String):FlxGraphic
	{
		var path:String = Paths.getPath('${fontName}/${fontName}.png', "fonts");
		return Cache.getGraphic(path);
	}

	private static function getCode(fontName:String):String
	{
		var path:String = Paths.getPath('${fontName}/${fontName}.xml', "fonts");
		return Assets.getText(path);
	}

	public static function setProperties(text:FlxBitmapText, setBorder:Bool = true, targetSize:Float = 0.35)
	{
		if (setBorder)
			text.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);

		text.scrollFactor.set();
		text.autoSize = false;
		text.alignment = LEFT;
		text.fieldWidth = FlxG.width;
		text.antialiasing = SaveData.antialiasing;
		changeFontSize(text, targetSize);
	}

	public static function changeFontSize(text:FlxBitmapText, targetSize:Float = 0.35)
	{
		text.setGraphicSize(Std.int(text.width * targetSize));
		text.centerOrigin();
		text.updateHitbox();
	}
}
