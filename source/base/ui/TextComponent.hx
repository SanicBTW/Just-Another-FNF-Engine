package base.ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;

// kind of based off flxtext schema but modified to only use one bitmap and reuse it, draws into the pixels of the sprite - i couldnt really like update the graphic cuz i dont want to cache a bunch of shit lol so just gonna mult fieldwitdh by 2 on bitmap
// todo: improve the width shit
class TextComponent extends FlxSprite
{
	// Needed for drawing
	private var _bitmap:BitmapData;
	private var _drawRect:Rectangle;
	private var _zeroOffset:Point;

	private var _swagMatrix:Matrix;

	// Border drawing
	private var _borderBitmap:BitmapData;

	// The text
	private var textField:TextField;

	private static inline final VERTICAL_GUTTER:Int = 4;

	// Variables to modify text field
	public var text(get, set):String;
	public var fieldWidth(get, set):Float;
	public var autoSize(get, set):Bool;

	private function get_text():String
		return (textField != null) ? textField.text : "";

	private function set_text(Text:String):String
	{
		if (text == Text)
			return text;

		if (textField == null)
			return text;

		textField.text = Text;

		return Text;
	}

	private function get_fieldWidth():Float
		return (textField != null) ? textField.width : 0;

	private function set_fieldWidth(value:Float):Float
	{
		if (textField == null)
			return value;

		if (value <= 0)
		{
			textField.wordWrap = false;
			autoSize = true;
		}
		else
		{
			autoSize = false;
			textField.wordWrap = true;
			textField.width = value;
		}

		return value;
	}

	private function get_autoSize():Bool
		return (textField != null) ? (textField.autoSize != TextFieldAutoSize.NONE) : false;

	private function set_autoSize(value:Bool):Bool
	{
		if (textField == null)
			return value;

		textField.autoSize = value ? TextFieldAutoSize.LEFT : TextFieldAutoSize.NONE;
		return value;
	}

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, Text:String = "placeholder", Size:Int = 12, Font:String = "vcr.ttf")
	{
		super(X, Y);

		allowCollisions = NONE;
		moves = false;

		textField = new TextField();
		textField.selectable = false;
		textField.mouseEnabled = false;
		textField.multiline = true;
		textField.wordWrap = true;
		textField.embedFonts = true;
		textField.defaultTextFormat = new TextFormat(Paths.font(Font), Size, 0xFFFFFF);
		textField.sharpness = 400;

		text = Text;
		fieldWidth = FieldWidth;

		_bitmap = Cache.setBitmap("txtBitmap",
			new BitmapData(Std.int(fieldWidth * 1.5), Std.int(textField.textHeight) + VERTICAL_GUTTER, true, FlxColor.TRANSPARENT));
		_borderBitmap = Cache.setBitmap("txtBBitmap",
			new BitmapData(Std.int(fieldWidth * 1.5), Std.int(textField.textHeight) + VERTICAL_GUTTER, true, FlxColor.BLACK));
		_drawRect = new Rectangle(0, 0, fieldWidth * 1.5, textField.textHeight + VERTICAL_GUTTER);
		_zeroOffset = new Point();
		_swagMatrix = new Matrix();

		makeGraphic(Std.int(_drawRect.width), Std.int(_drawRect.height), FlxColor.TRANSPARENT, true);
	}

	override public function destroy()
	{
		_bitmap = null;
		Cache.disposeBitmap("txtBitmap");
		Cache.disposeBitmap("txtBBitmap");
		_drawRect = null;
		_zeroOffset = null;

		textField = null;

		super.destroy();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// Clean buffers
		_bitmap.fillRect(_drawRect, FlxColor.TRANSPARENT);
		_borderBitmap.fillRect(_drawRect, FlxColor.TRANSPARENT);

		// Restart matrix and set borders
		_swagMatrix.identity();
		showBorder(1);

		// Draw the text field into the bitmap and copy pixels
		_bitmap.draw(textField, _swagMatrix);
		pixels.copyPixels(_bitmap, _drawRect, _zeroOffset);
	}

	private function showBorder(size:Float)
	{
		var iterations:Int = Std.int(size * 1);
		if (iterations <= 0)
			iterations = 1;
		var delta:Float = size / iterations;

		var curDelta:Float = delta;
		for (i in 0...iterations)
		{
			copyWithOffset(-curDelta, -curDelta);
			copyWithOffset(curDelta, 0);
			copyWithOffset(curDelta, 0);
			copyWithOffset(0, curDelta);
			copyWithOffset(0, curDelta);
			copyWithOffset(-curDelta, 0);
			copyWithOffset(-curDelta, 0);
			copyWithOffset(0, -curDelta);

			_swagMatrix.translate(curDelta, 0);
			curDelta += delta;
		}
	}

	public function copyWithOffset(x:Float, y:Float)
	{
		_swagMatrix.translate(x, y);
		_borderBitmap.draw(textField, _swagMatrix);
	}
}
