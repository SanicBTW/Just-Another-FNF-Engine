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

using flixel.util.FlxColorTransformUtil;

// kind of based off flxtext schema but modified to only use one bitmap and reuse it, draws into the pixels of the sprite - i couldnt really like update the graphic cuz i dont want to cache a bunch of shit lol so just gonna mult fieldwitdh by 2 on bitmap
// todo: improve the width shit
// some stuff is literally straight up copied from flx text my bad
class TextComponent extends FlxSprite
{
	// Needed for drawing
	private var _bitmap:BitmapData;
	private var _drawRect:Rectangle;
	private var _zeroOffset:Point;

	private var _swagMatrix:Matrix;

	// Border drawing
	private var _borderBitmap:BitmapData;
	private var _borderColorTransform:ColorTransform;
	private var _hasBorderAlpha:Bool = false;

	// The text
	private var textField:TextField;
	private var _defaultFormat:TextFormat;
	private var _formatAdjusted:TextFormat;

	private static inline final VERTICAL_GUTTER:Int = 4;

	// Variables to modify text field
	public var text(get, set):String;
	public var fieldWidth(get, set):Float;
	public var autoSize(get, set):Bool;
	public var borderSize:Float = 1;
	public var borderColor(default, set):FlxColor;

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

	private function set_borderColor(Color:FlxColor):FlxColor
	{
		if (borderColor == Color)
			return Color;

		if (borderSize <= 0)
			return Color;

		if (_borderColorTransform == null)
			_borderColorTransform = new ColorTransform();

		_hasBorderAlpha = Color.alphaFloat < 1;
		return borderColor = Color;
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
		_defaultFormat = new TextFormat(Paths.font(Font), Size, 0xFFFFFF);
		textField.defaultTextFormat = _defaultFormat;
		_formatAdjusted = new TextFormat();
		textField.sharpness = 400;

		text = Text;
		fieldWidth = FieldWidth;

		_bitmap = Cache.setBitmap("txtBitmap",
			new BitmapData(Std.int(fieldWidth * 1.5), Std.int(textField.textHeight) + VERTICAL_GUTTER, true, FlxColor.TRANSPARENT));
		_borderBitmap = Cache.setBitmap("txtBBitmap",
			new BitmapData(Std.int(fieldWidth * 1.5), Std.int(textField.textHeight) + VERTICAL_GUTTER, true, FlxColor.TRANSPARENT));
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
		_defaultFormat = null;
		_formatAdjusted = null;
		_zeroOffset = null;

		textField = null;

		super.destroy();
	}

	override public function draw()
	{
		// Clean buffers
		_bitmap.fillRect(_drawRect, FlxColor.TRANSPARENT);
		if (_hasBorderAlpha)
			_borderBitmap.fillRect(_drawRect, FlxColor.TRANSPARENT);

		// Set necessary stuff
		copyFormat(_defaultFormat, _formatAdjusted);

		_swagMatrix.identity();

		showBorder();
		borderTrans();
		applyFormat(_formatAdjusted, false);

		// Draw the text field into the bitmap and copy pixels
		_bitmap.draw(textField, _swagMatrix);
		pixels.copyPixels(_bitmap, _drawRect, _zeroOffset);
		super.draw();
	}

	private function showBorder()
	{
		var iterations:Int = Std.int(borderSize * 1);
		if (iterations <= 0)
			iterations = 1;
		var delta:Float = borderSize / iterations;

		applyFormat(_formatAdjusted, true);

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

	private function borderTrans()
	{
		if (!_hasBorderAlpha)
			return;

		if (_borderColorTransform == null)
			_borderColorTransform = new ColorTransform();

		_borderColorTransform.alphaMultiplier = borderColor.alphaFloat;
		_borderBitmap.colorTransform(_drawRect, _borderColorTransform);
		_bitmap.draw(_borderBitmap);
	}

	private function copyWithOffset(x:Float, y:Float)
	{
		var graphic:BitmapData = _hasBorderAlpha ? _borderBitmap : _bitmap;
		_swagMatrix.translate(x, y);
		graphic.draw(textField, _swagMatrix);
	}

	private function applyFormat(FormatAdjusted:TextFormat, UseBorderColor:Bool = false)
	{
		copyFormat(_defaultFormat, FormatAdjusted, false);
		FormatAdjusted.color = UseBorderColor ? borderColor.to24Bit() : _defaultFormat.color;
		textField.setTextFormat(FormatAdjusted);
	}

	private function copyFormat(from:TextFormat, to:TextFormat, withAlign:Bool = true)
	{
		to.font = from.font;
		to.bold = from.bold;
		to.italic = from.italic;
		to.size = from.size;
		to.color = from.color;
		to.leading = from.leading;
		if (withAlign)
			to.align = from.align;
	}
}
