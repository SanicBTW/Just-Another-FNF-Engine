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
		timeBarBG.screenCenter(flixel.util.FlxAxes.X);

		timeText = new TextComponent(0, 0, timeBarBG.width, "0:00", 32);
		timeText.alignment = CENTER;
		timeText.borderSize = 2;
		timeText.setPosition((timeBarBG.x / 4) + (timeText.width / 2), (timeBarBG.y / 2) - (timeText.height / 4));

		timeBar = new Bar(timeBarBG.x + 4, timeBarBG.y + 4, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), 0xFF000000, 0xFFFFFFFF);
		timeBar.screenCenter(flixel.util.FlxAxes.X);
		timeBarBG.sprTracker = timeBar;

		add(timeBarBG);
		add(timeBar);
		add(timeText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 8.6), 0, 1);

		var curTime:Float = Conductor.songPosition;
		if (curTime < 0)
			curTime = 0;

		timeBar.value = FlxMath.lerp((curTime / Conductor.boundSong.length), timeBar.value, lerpVal);

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
