package window.debug;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;

@:allow(flixel.FlxGame)
class FramerateCounter extends OFLSprite
{
	public var currentFPS(default, null):Float;

	// time since last check shit something dunno
	public var timeLast(default, null):Float;

	@:noCompletion private var prevTime:Float = Date.now().getTime();

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	private var bg:Shape;
	private var fpsText:TextField;
	private var offsetWidth:Float = 7;

	// lerping haha
	public var targetX:Float = 0;
	public var targetY:Float = 0;

	override public function new(X:Float = 10, Y:Float = 10)
	{
		super();

		targetX = X;
		targetY = Y;

		currentFPS = 0;
		cacheCount = 0;
		currentTime = 0;
		times = [];
		mouseEnabled = false;
	}

	override public function create()
	{
		fpsText = new TextField();
		fpsText.text = 'FPS: 0';
		fpsText.embedFonts = true;
		fpsText.defaultTextFormat = new TextFormat(getFont('open_sans.ttf').fontName, 12, 0xFFFFFF);
		fpsText.selectable = false;
		fpsText.autoSize = LEFT;

		bg = drawRound(x, y, fpsText.textWidth + offsetWidth, fpsText.textHeight + 5, [5], FlxColor.BLACK, 0.5);

		addChild(bg);
		addChild(fpsText);
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = boundTo(1 - (elapsed * 8.6), 0, 1);

		// bg shit
		lerpTrack(bg, "width", fpsText.textWidth + offsetWidth, lerpVal);
		lerpTrack(bg, "x", targetX, lerpVal);
		lerpTrack(bg, "y", targetY, lerpVal);

		// text shit
		lerpTrack(fpsText, "x", bg.x, lerpVal);
		lerpTrack(fpsText, "y", bg.y, lerpVal);
		updateFPSText(lerpVal);
	}

	private function updateFPSText(lerpVal:Float)
	{
		var prevTime:Float = this.prevTime;
		var time:Float = Date.now().getTime();

		currentTime += rawElapsed;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		currentFPS = Math.round((times.length + cacheCount) / 2);

		if (times.length != cacheCount)
		{
			if (time > prevTime + 1000)
			{
				timeLast = FlxMath.roundDecimal(((time - prevTime) / 10000), 2);
				this.prevTime = time;
			}

			fpsText.text = 'FPS: $currentFPS (${timeLast}ms)';
		}

		if (currentFPS < FlxG.updateFramerate / 2)
			fpsText.textColor = FlxColor.interpolate(0xFFFFFFFF, 0xFFFF0000, lerpVal);
		else
			fpsText.textColor = FlxColor.interpolate(0xFFFF0000, 0xFFFFFFFF, lerpVal);

		cacheCount = times.length;
	}
}
