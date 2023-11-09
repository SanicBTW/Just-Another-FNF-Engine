package base.sprites;

import flixel.FlxG;
import openfl.text.TextField;

// I thought about it and asked galo about it
/*
	so if flxtext makes you create graphics to just copy pixels to that graphic from a openfl sprite
	why not just create the openfl sprite and append it to the camera canvas, it requires further testing
	but the old approach or idea was just to copy the openfl sprite pixels to the camera buffer
	but seemed like a little bit of work
 */
class CanvasText
{
	var _textField:TextField;

	public function new(X:Float, Y:Float, Text:String)
	{
		_textField = new TextField();
		_textField.x = X;
		_textField.y = Y;
		_textField.text = Text;

		FlxG.camera.canvas.addChild(_textField);
	}
}
