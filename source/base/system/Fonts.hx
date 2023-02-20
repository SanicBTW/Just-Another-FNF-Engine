package base.system;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxBitmapFont;
import openfl.Assets;

class Fonts
{
	public static inline function VCR():FlxBitmapFont
		return FlxBitmapFont.fromAngelCode(getGraphic("VCR"), getCode("VCR"));

	public static function getGraphic(fontName:String):FlxGraphic
	{
		var path:String = Paths.getLibraryPath('${fontName}/${fontName}.png', "fonts");
		return Cache.getGraphic(path);
	}

	public static function getCode(fontName:String):String
	{
		var path:String = Paths.getLibraryPath('${fontName}/${fontName}.xml', "fonts");
		return Assets.getText(path);
	}
}
