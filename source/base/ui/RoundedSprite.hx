package base.ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

// totally not from https://github.com/SanicBTW/FNF-PsychEngine-0.5.2h/blob/master/source/Prompt.hx
class RoundedSprite extends FlxSprite
{
	private var cornerSize(default, set):Float = 10;
	private var Color:FlxColor;

	private function set_cornerSize(Value:Float):Float
	{
		if (cornerSize == Value)
			return Value;

		cornerSize = Value;
		regen();
		return Value;
	}

	override public function new(X:Float, Y:Float, Width:Float, Height:Float, Color:FlxColor)
	{
		super(X, Y);
		this.width = Width;
		this.height = Height;
		this.Color = Color;

		makeGraphic(Std.int(width), Std.int(height), Color, true);
		regen();
	}

	private function regen()
	{
		pixels.fillRect(new Rectangle(0, 0, cornerSize, cornerSize), 0x0);
		round(false, false);
		pixels.fillRect(new Rectangle(width - cornerSize, 0, cornerSize, cornerSize), 0x0);
		round(true, false);
		pixels.fillRect(new Rectangle(0, height - cornerSize, cornerSize, cornerSize), 0x0);
		round(false, true);
		pixels.fillRect(new Rectangle(width - cornerSize, height - cornerSize, cornerSize, cornerSize), 0x0);
		round(true, true);
	}

	private function round(flipX:Bool, flipY:Bool)
	{
		var antiX:Float = (width - cornerSize);
		var antiY:Float = flipY ? (height - 1) : 0;
		if (flipY)
			antiY -= 2;
		pixels.fillRect(new Rectangle((flipX ? antiX : 1), Math.abs(antiY - 8), 10, 3), Color);
		if (flipY)
			antiY += 1;
		pixels.fillRect(new Rectangle((flipX ? antiX : 2), Math.abs(antiY - 6), 9, 2), Color);
		if (flipY)
			antiY += 1;
		pixels.fillRect(new Rectangle((flipX ? antiX : 3), Math.abs(antiY - 5), 8, 1), Color);
		pixels.fillRect(new Rectangle((flipX ? antiX : 4), Math.abs(antiY - 4), 7, 1), Color);
		pixels.fillRect(new Rectangle((flipX ? antiX : 5), Math.abs(antiY - 3), 6, 1), Color);
		pixels.fillRect(new Rectangle((flipX ? antiX : 6), Math.abs(antiY - 2), 5, 1), Color);
		pixels.fillRect(new Rectangle((flipX ? antiX : 8), Math.abs(antiY - 1), 3, 1), Color);
	}
}
