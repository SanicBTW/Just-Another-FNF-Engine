package base.ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;

class TextComponent extends FlxSprite
{
	private var _bgBit:BitmapData;
	private var _bgRect:Rectangle;
	private var _zeroOffset:Point;

	private var txtField:TextField;

	public var text(default, set):String;

	private function set_text(newText:String):String
	{
		if (text == newText)
			return text;

		if (txtField == null)
			return text;

		text = newText;
		txtField.text = text;

		return text;
	}

	public function new(X:Float = 0, Y:Float = 0, Width:Int = 0, Height:Int = 0, Text:String = "", Size:Int = 12, Font:String = "vcr.ttf")
	{
		super(x, y);

		this.width = Width;
		this.height = Height;

		Cache.setBitmap("bgTxtBitmap", new BitmapData(Width, Height, true, FlxColor.TRANSPARENT));

		txtField = new TextField();
		txtField.selectable = false;
		txtField.mouseEnabled = false;
		txtField.multiline = true;
		txtField.wordWrap = true;
		txtField.text = Text;
		txtField.sharpness = 400;
		txtField.width = Width;
		txtField.height = Height;
		txtField.defaultTextFormat = new TextFormat(Paths.font(Font), Size, 0xFFFFFF);
		txtField.defaultTextFormat.align = CENTER;

		_bgBit = Cache.setBitmap("bgTxtBitmap");
		_bgRect = new Rectangle(0, 0, Width, Height);
		_zeroOffset = new Point();

		makeGraphic(Width, Height, FlxColor.TRANSPARENT, true);
	}

	override public function destroy()
	{
		_bgBit = null;
		Cache.disposeBitmap("bgTxtBitmap");
		_bgRect = null;
		_zeroOffset = null;

		txtField = null;

		super.destroy();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		_bgBit.fillRect(_bgRect, FlxColor.TRANSPARENT);
		_bgBit.draw(txtField);
		pixels.copyPixels(_bgBit, _bgRect, _zeroOffset);
	}
}
