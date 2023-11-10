package funkin;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

enum ButtonType
{
	OK_CANCEL;
	ARROWS;
	ON_OFF;
	NONE;
}

enum abstract OKC_Buttons(String) to String
{
	var OK = "ok_buttons";
	var CANCEL = "cancel_buttons";
}

enum abstract Arrow_Buttons(String) to String
{
	var UP = "arrow_up_button";
	var MOVE_UP = "move_up_button"; // not used
	var DOWN = "arrow_down_button";
}

enum abstract OF_Buttons(String) to String
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
				loadGraphic(Paths.image('ui/prompt/$_btn'), true, 45, 45);

			case OK_CANCEL:
				loadGraphic(Paths.image('ui/prompt/$_btn'), true, 167, 60);

			case NONE:
				return;
		}
	}
}

class Prompt extends FlxSpriteGroup
{
	public var title:FlxText;
	public var info:FlxText;

	public var button1:PromptButton;
	public var button2:PromptButton;

	public function new(title:String, description:String, type:ButtonType)
	{
		super();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/prompt/promptbg'));
		add(bg);

		this.title = new FlxText(bg.x + 105, bg.y + 30, bg.width - 132, title, 25);
		this.title.setFormat(Paths.font("vcr.ttf"), 25, flixel.util.FlxColor.BLACK, LEFT);
		this.title.disableCaching = true;
		add(this.title);

		this.info = new FlxText(bg.x + 12, this.title.y + 50, bg.width - 32, description, 20);
		this.info.setFormat(Paths.font("vcr.ttf"), 20, flixel.util.FlxColor.BLACK, LEFT);
		this.info.disableCaching = true;
		add(this.info);

		switch (type)
		{
			case ARROWS:
				button1 = new PromptButton(bg.x + 15, bg.y + 275, null, type, Arrow_Buttons.DOWN);
				button2 = new PromptButton(button1.x + 285, button1.y, null, type, Arrow_Buttons.UP);

			case OK_CANCEL:
				button1 = new PromptButton(bg.x + 15, bg.y + 260, null, type, OKC_Buttons.OK);
				button2 = new PromptButton((button1.x + button1.width) + 2.5, button1.y, null, type,
					OKC_Buttons.CANCEL); // 2.5 margin from the original spritesheet?

			default:
		}

		add(button1);
		add(button2);
	}
}
