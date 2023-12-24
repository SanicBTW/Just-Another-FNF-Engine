package flixel.addons.ui;

import flixel.addons.ui.FlxInputText;
// From https://github.com/HaxeFlixel/flixel-ui/issues/70#issuecomment-1035841072
/**
 * This is so hackish I might just marry it.
 *
 * On desktop/html5, this acts as (and IS) a regular input. I suspect that html5 should go the mobile route if it's
 * running on an actual mobile device, but I'll check that later
 *
 * Anyway, on mobile, we use a set of devious hacks to get a virtual keyboard to popup on screen. That keyboard inputs
 * to a hidden OpenFL field and we constantly copy the content of that field to our real/visible FlxInputText. We then
 * mimick some properties of FlxInputText using getters and setters. We use a ClickArea to set focus on the hidden
 * OpenFL field, and we also listen to enter keypresses to dismiss the keyboard by removing focus from the field. We
 * also need special care to manually deal with maxLength, because the FlxText setter does not honour MaxLength on its
 * own.
 *
 * Overall it's a very hacky solution on mobile, but it works!
**/
#if !mobile
typedef GFTextInput = FlxInputText;
#else
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;

class GFTextInput extends FlxSpriteGroup
{
	public final inputText:FlxInputText;

	private final _flTextField:openfl.text.TextField;
	private final clickArea:ClickArea;

	public var maxLength(default, set):Int;
	public var text(get, set):String;

	public function new(X:Float = 0, Y:Float = 0, Width:Int = 150, ?Text:String, size:Int = 8, TextColor:Int = FlxColor.BLACK,
			BackgroundColor:Int = FlxColor.WHITE, EmbeddedFont:Bool = true)
	{
		super();
		x = X;
		y = Y;
		inputText = new FlxInputText(x, y, Width, Text, size, TextColor, BackgroundColor, EmbeddedFont);
		_flTextField = new openfl.text.TextField();
		_flTextField.needsSoftKeyboard = true;
		_flTextField.text = text;
		_flTextField.x = x;
		_flTextField.y = y;
		_flTextField.type = openfl.text.TextFieldType.INPUT;
		_flTextField.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, function(e:openfl.events.KeyboardEvent)
		{
			if (inputText.maxLength == 0 || _flTextField.text.length <= inputText.maxLength)
				inputText.text = _flTextField.text;
			if (e.keyCode == 13)
				FlxG.stage.focus = null;
		});
		clickArea = new ClickArea(x, y, Width, inputText.height, function()
		{
			text = '';
			FlxG.stage.focus = _flTextField;
		});
		add(inputText);
		add(clickArea);
		FlxG.addChildBelowMouse(_flTextField);
	}

	public override function update(elapsed)
	{
		if (inputText.maxLength == 0 || _flTextField.text.length <= inputText.maxLength)
			inputText.text = _flTextField.text;
		super.update(elapsed);
	}

	@:noCompletion
	override private function set_x(v:Float)
	{
		if (inputText != null)
			inputText.x = v;

		if (clickArea != null)
			clickArea.x = v;

		return x = v;
	}

	@:noCompletion
	override private function set_y(v:Float)
	{
		if (inputText != null)
			inputText.y = v;

		if (clickArea != null)
			clickArea.y = v;

		return y = v;
	}

	@:noCompletion
	private function set_text(value:String):String
	{
		inputText.text = value;
		_flTextField.text = value;

		return value;
	}

	@:noCompletion
	private function get_text():String
	{
		return inputText.text;
	}

	@:noCompletion
	private function set_maxLength(v:Int):Int
	{
		return maxLength = inputText.maxLength = v;
	}

	public override function destroy()
	{
		FlxG.removeChild(_flTextField);
	}
}
#end

/**
 * A clickarea. Basically an invisible button to put over things.
**/
class ClickArea extends FlxUIButton
{
	public var onClick:Void->Void;

	public function new(x:Float, y:Float, width:Float, height:Float, onClick:Void->Void = null)
	{
		super(x, y, null, false, true);
		this.width = width;
		this.height = height;
		this.onClick = onClick;
		immovable = true;
		scrollFactor.set();
		onUp.callback = function()
		{
			if (this.onClick != null)
				this.onClick();
		};
	}
}
