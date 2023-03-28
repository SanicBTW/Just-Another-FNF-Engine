package funkin.ui;

import base.system.Conductor;
import base.ui.Bar;
import base.ui.Sprite.AttachedSprite;
import base.ui.TextComponent;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

// Sprite class to track the song time
// A bar to track the progres and Text for the time left
// Come back later
@:allow(funkin.ui.UI)
class TimeTracker extends FlxSpriteGroup
{
	private var timeText:TextComponent;
	private var timeBarBG:AttachedSprite;
	private var timeBar:Bar;

	public function new(X:Float, Y:Float)
	{
		super(X, Y);

		antialiasing = SaveData.antialiasing;
		scrollFactor.set();

		timeBarBG = new AttachedSprite("ui/timeBar");
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;

		timeText = new TextComponent(0, 0, 400, "0:00", 32);
		timeText.alignment = CENTER;
		timeText.borderSize = 2;
		timeText.scrollFactor.set();
		timeText.setPosition(42 + (FlxG.width / 2) - 248, Y - timeText.height);

		timeBar = new Bar(timeBarBG.x + 4, timeBarBG.y + 4, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), 0xFF000000, 0xFFFFFFFF);
		timeBar.screenCenter(flixel.util.FlxAxes.X);
		timeBar.scrollFactor.set();
		timeBarBG.sprTracker = timeBar;

		add(timeBarBG);
		add(timeBar);
		add(timeText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var curTime:Float = Conductor.songPosition;
		if (curTime < 0)
			curTime = 0;

		timeBar.value = (curTime / Conductor.boundSong.length);

		var secondsTotal:Int = Math.floor((Conductor.boundSong.length - curTime) / 1000);
		if (secondsTotal < 0)
			secondsTotal = 0;

		var minutesRemaining:Int = Math.floor(secondsTotal / 60);
		var secondsRemaining:String = '${secondsTotal % 60}';
		if (secondsRemaining.length < 2)
			secondsRemaining = '0$secondsRemaining';

		timeText.text = '${minutesRemaining}:${secondsRemaining}';
	}
}
