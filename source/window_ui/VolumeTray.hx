package window_ui;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import funkin.CoolUtil;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;

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
	private var _volBar:Bitmap;

	// Volume
	private var volume(get, null):Float;

	@:noCompletion
	private function get_volume():Float
		return FlxG.sound != null ? FlxG.sound.volume : 1;

	override public function create()
	{
		super.create();

		y = -Lib.current.stage.stageHeight;

		var bg:Bitmap = new Bitmap(new BitmapData(_width, _height, true, 0x7F000000));
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

		_volBar = new Bitmap(new BitmapData(_width - 10, 5, false, FlxColor.WHITE));
		_volBar.x = 5;
		_volBar.y = (_height - _volBar.height) - 5;
		addChild(_volBar);
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 8.6), 0, 1);

		y = FlxMath.lerp(targetY, y, lerpVal);
		_volBar.scaleX = FlxMath.lerp((FlxG.sound.muted ? 0 : volume), _volBar.scaleX, lerpVal);
		_volTracker.text = '${Math.round(_volBar.scaleX * 100)}%';

		if (_visibleTime > 0)
			_visibleTime -= elapsed;
		else if (y > -height)
		{
			targetY -= elapsed * FlxG.height * _defaultScale;

			if (y <= -height)
			{
				visible = false;
				active = false;
			}
		}

		super.update(elapsed);
	}

	public function show()
	{
		_visibleTime = 1.8;
		targetY = 0;
		visible = true;
		active = true;
	}

	private function setTxtFieldProperties(field:TextField)
	{
		field.defaultTextFormat = new TextFormat(Assets.getFont(Paths.font("funkin.otf")).fontName, 10, 0xFFFFFF);
		field.width = _width;
		field.height = _height;
		field.multiline = true;
		field.wordWrap = true;
		field.selectable = false;
		field.embedFonts = true;
		field.y = 2.5;
	}
}
