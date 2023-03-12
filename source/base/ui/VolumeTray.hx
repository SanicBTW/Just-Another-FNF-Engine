package base.ui;

import base.system.SoundManager;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import funkin.CoolUtil;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

// Based off FlxSoundTray, thought on making rounded stuff but seems hard? or maybe its just that im too lazy
// Just gonna get the basics done, once I get them I will start making a better design I promise
class VolumeTray extends Sprite
{
	public var active:Bool;

	private var _visibleTime:Float;
	private var _width:Int = 80;
	private var _defaultScale:Float = 2.0;

	private var _volBar:Bitmap;

	private var targetHeight:Float = 0;

	private var elapsed(get, null):Float;

	private function get_elapsed():Float
		return FlxG.elapsed;

	@:keep
	public function new()
	{
		super();

		visible = false;
		var bg:Bitmap = new Bitmap(new BitmapData(_width, 30, true, 0x7F000000));
		screenCenter();
		addChild(bg);

		var text:TextField = new TextField();
		text.width = bg.width;
		text.height = bg.height;
		text.multiline = true;
		text.wordWrap = true;
		text.selectable = false;
		text.embedFonts = true;
		text.defaultTextFormat = new TextFormat(Assets.getFont(Paths.font("funkin.otf")).fontName, 10, 0xFFFFFF);
		text.defaultTextFormat.align = CENTER;
		addChild(text);

		text.text = "Volume";
		text.y = 16;

		_volBar = new Bitmap(new BitmapData(_width - 10, 5, false, FlxColor.WHITE));
		_volBar.x = 5;
		_volBar.y = 5;
		addChild(_volBar);

		y = -height;
		visible = false;
	}

	public function update()
	{
		var lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 5.125), 0, 1);

		y = FlxMath.lerp(targetHeight, y, lerpVal);
		_volBar.scaleX = FlxMath.lerp(SoundManager.globalVolume, _volBar.scaleX, lerpVal);

		if (_visibleTime > 0)
			_visibleTime -= elapsed;
		else if (y > -height)
		{
			targetHeight -= elapsed * FlxG.height * 2;

			if (y <= -height)
			{
				visible = false;
				active = false;
			}
		}
	}

	public function show()
	{
		_visibleTime = 2;
		targetHeight = 0;
		visible = true;
		active = true;
	}

	public function screenCenter()
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}
}
