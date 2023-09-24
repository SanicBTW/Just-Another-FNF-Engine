package funkin;

import backend.Cache;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;

enum ButtonType
{
	OK_CANCEL;
	ARROWS;
	ON_OFF;
	NONE;
}

enum abstract OKC_Buttons(String) to String {}

enum abstract Arrow_Buttons(String) to String
{
	var UP = "arrow_up_button";
	var MOVE_UP = "move_up_button";
	var DOWN = "arrow_down_button";
}

enum abstract OOFF_Buttons(String) to String
{
	var ON = "on_button";
	var OFF = "off_button";
}

class PromptButton extends FlxTypedButton<FlxSprite>
{
	private var _type:ButtonType = NONE;
	private var _btn:String = ""; // use the enum abstract fields to select the button

	public function new(X:Float = 0, Y:Float = 0, ?OnClick:Void->Void, type:ButtonType = NONE, button:String = "")
	{
		this._type = type;
		this._btn = button;
		super(X, Y, OnClick);
	}

	override function loadDefaultGraphic()
	{
		switch (_type)
		{
			case ARROWS | ON_OFF:
				loadGraphic(Paths.image('ui/$_btn'), true, 45, 45);

			// havent done them yet
			case NONE | OK_CANCEL:
				return;
		}
	}
}

class Prompt extends FlxSpriteGroup {}
