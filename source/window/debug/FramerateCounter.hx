package window.debug;

import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;

@:allow(flixel.FlxGame)
class FramerateCounter extends OFLSprite
{
	public var currentFPS(default, null):Float;

	private var cacheCount:Int;
	private var times:Array<Float>;

	private var bg:Shape;
	private var fpsText:TextField;

	private var padding:Array<Float> = [15, 15];

	private var fontSize:Int = 16;

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
		times = [];
		mouseEnabled = false;
	}

	override public function create()
	{
		fpsText = new TextField();
		fpsText.text = 'FPS: 0';
		fpsText.embedFonts = true;
		fpsText.defaultTextFormat = new TextFormat(getFont('open_sans.ttf').fontName, fontSize, 0xFFFFFF);
		fpsText.selectable = false;
		fpsText.autoSize = LEFT;

		bg = drawRound(x, y, fpsText.textWidth + padding[0], fpsText.height + padding[1], [10], FlxColor.BLACK, 0.5);

		addChild(bg);
		addChild(fpsText);
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = boundTo(1 - (elapsed * 8.6), 0, 1);

		// bg sizes
		lerpTrack(bg, "width", fpsText.textWidth + padding[0], lerpVal);
		lerpTrack(bg, "height", fpsText.textHeight + padding[1], lerpVal);

		// bg pos
		lerpTrack(bg, "x", targetX, lerpVal);
		lerpTrack(bg, "y", targetY, lerpVal);

		// text pos based off bg pos and some shitty center calculation
		// it only works with 15 padding lol
		lerpTrack(fpsText, "x", bg.x + ((bg.width - fpsText.textWidth) / 2) - padding[0] / 4, lerpVal);
		lerpTrack(fpsText, "y", bg.y + ((bg.height - fpsText.textHeight) / 2) - padding[1] / 4, lerpVal);
		updateFPSText();
	}

	private function updateFPSText()
	{
		var now:Float = haxe.Timer.stamp();
		times.push(now);

		while (times[0] < now - 1)
		{
			times.shift();
		}

		currentFPS = Math.round((times.length + cacheCount) / 2);

		if (times.length != cacheCount)
			fpsText.text = 'FPS: $currentFPS';

		if (currentFPS < FlxG.updateFramerate / 2)
			fpsText.textColor = 0xFFFF0000;
		else
			fpsText.textColor = 0xFFFFFFFF;

		cacheCount = times.length;
	}
}
