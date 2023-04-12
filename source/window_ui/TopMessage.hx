package window_ui;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import funkin.CoolUtil;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

// Could be possible to slide the 0th child down to let the top message show??? (0th child should and must be FlxGame soo)
class TopMessage extends Tray
{
	// Time visible
	private var _visibleTime:Float = 0.0;

	// Sizes
	private var _width:Int = Lib.current.stage.stageWidth;
	private var _height:Int = 50;

	// Lerping
	private var targetY:Float = 0.0;

	// Message stuff
	private var content:String;
	private var type:String;

	override public function new(content:String, type:String = "")
	{
		super();
		this.content = content;
		this.type = type;
	}

	override private function create()
	{
		super.create();

		y = 0;
		active = true;
		visible = true;
		_visibleTime = 5;

		var bg:Bitmap = new Bitmap(new BitmapData(_width, _height, false, FlxColor.fromRGB(79, 83, 88)));
		screenCenter();
		addChild(bg);
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 8.6), 0, 1);

		y = FlxMath.lerp(targetY, y, lerpVal);
		Main.game.y = FlxMath.lerp(targetY + (_height * _defaultScale), Main.game.y, lerpVal);

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
}
