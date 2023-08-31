package window.ui;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.text.TextField;
import openfl.text.TextFormat;
import window.components.RoundedSprite;

using StringTools;

class VolumeTray extends Tray
{
	// Time visible
	private var _visibleTime:Float = 0.0;

	// Sizes
	private var _width:Int = 120;
	private var _height:Int = 30;

	// For lerp
	private var targetX:Float = 0.0;
	private var targetY:Float = 0.0;

	// Sprites
	private var _volTracker:TextField; // temp and the vol tracker?
	private var _volBar:RoundedSprite;

	// Volume
	private var volume(get, null):Float;

	@:noCompletion
	private function get_volume():Float
		return FlxG.sound != null ? FlxG.sound.volume : 1;

	override public function create()
	{
		y = -Lib.current.stage.stageHeight;

		var bg:RoundedSprite = new RoundedSprite(0, 0, _width, _height, [0, 0, 10, 10], FlxColor.BLACK, 0.6);
		screenCenter();
		addChild(bg);

		// Not kept in variable because this one doesn't update
		var volText:TextField = new TextField();
		setTxtFieldProperties(volText);
		volText.text = "Volume";
		volText.defaultTextFormat.align = LEFT;
		volText.x = 5;
		addChild(volText);

		// This one gets updated when volume changes
		_volTracker = new TextField();
		setTxtFieldProperties(_volTracker);
		_volTracker.text = '${volume * 100}%';
		_volTracker.defaultTextFormat.align = RIGHT;
		_volTracker.x = (_width - _volTracker.textWidth) - 10;
		addChild(_volTracker);

		_volBar = new RoundedSprite(0, 0, _width - 10, 5, [5]);
		_volBar.x = 5;
		_volBar.y = (_height - _volBar.height) - 5;
		addChild(_volBar);
	}

	override public function update(elapsed:Float, _)
	{
		var lerpVal:Float = boundTo(1 - (elapsed * 8.6), 0, 1);

		y = FlxMath.lerp(targetY, y, lerpVal);

		_volBar.smoothSetSize((FlxG.sound.muted ? 0 : (_width - 10) * volume), _volBar.height, lerpVal);

		// because it isnt based off scaleX anymore and i have some issues with width, basically when its supposed to be 0 it goes to 5% as its min, its probably due to round stuff, will check it soon
		var prog:Float = (_volBar.width / (_width - 10)) * 100;
		if (Math.round(prog) <= 5)
			prog = 0;

		_volTracker.text = '${Math.round(prog)}%';

		// Only update it when it contains a 0 (lerp ended), make it an option or something lol
		// if (_volTracker.text.contains("0"))
		_volTracker.x = FlxMath.lerp((_width - _volTracker.textWidth) - 10, _volTracker.x, lerpVal);

		// Properly stop updating after the targetY is below the game height (kind of stupid!!!!! need to get another check!!!)
		if (_visibleTime > 0)
			_visibleTime -= elapsed;
		else if (_visibleTime <= 0)
		{
			if (targetY > -gHeight)
				targetY -= elapsed * gHeight * _defaultScale;
			else
			{
				visible = false;
				active = false;
			}
		}
	}

	public function show()
	{
		_visibleTime = 1.8;
		targetY = 0;
		visible = active = true;
	}

	private function setTxtFieldProperties(field:TextField)
	{
		field.defaultTextFormat = new TextFormat(getFont('funkin.otf').fontName, 10, 0xFFFFFF);
		field.width = _width;
		field.height = _height;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = false;
		field.embedFonts = true;
		#if !html5
		field.y = 2.5;
		#end
	}
}
