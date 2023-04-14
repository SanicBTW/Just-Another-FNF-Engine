package window_ui;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import funkin.CoolUtil;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;

// Could be possible to slide the 0th child down to let the top message show??? (0th child should and must be FlxGame soo)
class TopMessage extends Tray
{
	// Time visible
	private var _visibleTime:Float = 0.0;

	// Sizes
	private var _width:Int = Lib.current.stage.stageWidth;
	private var _height:Int = 40;

	// Lerping
	private var targetY:Float = 0.0;

	// Message stuff
	private var content:String;
	private var type:NotificationType;
	private var bgColor:FlxColor;

	// Elements that will be manipulated by lerps (to not fill the code with Main.ejasjasfj.jfasjfsa)
	private var game(get, null):FlxGame;

	@:noCompletion
	private function get_game():FlxGame
		return Main.game;

	private var fpsCounter(get, null):FramerateCounter;

	@:noCompletion
	private function get_fpsCounter():FramerateCounter
		return Main.fpsCounter;

	private var memoryCounter(get, null):MemoryCounter;

	@:noCompletion
	private function get_memoryCounter():MemoryCounter
		return Main.memoryCounter;

	override public function new(content:String, type:NotificationType = INFO)
	{
		this.content = content;
		this.type = type;
		super();
	}

	override private function create()
	{
		super.create();

		bgColor = switch (type)
		{
			case INFO:
				FlxColor.fromRGB(79, 83, 88);
			case WARNING:
				FlxColor.fromRGB(255, 215, 0);
			case ERROR:
				FlxColor.fromRGB(222, 49, 99);
		};

		y = 0;
		visible = true;
		active = true;
		_visibleTime = 3;

		var bg:Bitmap = new Bitmap(new BitmapData(_width, _height, true, bgColor));
		screenCenter();
		addChild(bg);
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 8.6), 0, 1);

		y = FlxMath.lerp(targetY, y, lerpVal);
		updateContainer(lerpVal);

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

		super.update(elapsed);
	}

	private function updateContainer(lerpVal:Float)
	{
		var slideY:Float = (targetY + _height) * _defaultScale;
		// bros starting y position is -1 :rofl:
		game.y = FlxMath.lerp(Math.max(slideY, -1), game.y, lerpVal);
		// also move the counters bro
		fpsCounter.y = FlxMath.lerp(Math.max(slideY, 8), fpsCounter.y, lerpVal);
		memoryCounter.y = FlxMath.lerp(Math.max(slideY, (fpsCounter.textHeight + fpsCounter.y) - 1), memoryCounter.y, lerpVal);
	}
}

enum abstract NotificationType(Int) to Int
{
	var INFO = 0;
	var WARNING = 1;
	var ERROR = 2;
}
