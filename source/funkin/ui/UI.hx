package funkin.ui;

#if use_flx_text
import flixel.text.FlxText;
#else
import base.ui.TextComponent;
#end
import base.Conductor;
import base.ui.Bar;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.Ratings;
import funkin.ui.JudgementCounter;

// more components are expected to be added and moved to their respective files
class UI extends FlxSpriteGroup
{
	#if use_flx_text
	private var accuracyText:FlxText;
	#else
	private var accuracyText:TextComponent;
	#end
	private var timeBar:Bar;

	public function new()
	{
		super();

		#if use_flx_text
		accuracyText = new FlxText(30, (FlxG.height / 2), 0, "Accuracy 0%", 24);
		accuracyText.scrollFactor.set();
		accuracyText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		accuracyText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		#else
		accuracyText = new TextComponent(30, (FlxG.height / 2), 0, 'Accuracy 0%', 24);
		accuracyText.scrollFactor.set();
		accuracyText.borderColor = FlxColor.BLACK;
		accuracyText.borderSize = 1;
		#end
		add(accuracyText);

		timeBar = new Bar(0, 0, FlxG.width, 10, FlxColor.WHITE, FlxColor.fromRGB(30, 144, 255));
		timeBar.screenCenter();
		timeBar.y = FlxG.height - 10;
		timeBar.screenCenter(X);
		add(timeBar);

		var judgementsArray:Array<String> = [];
		for (i in Ratings.judgements.keys())
			judgementsArray.insert(Ratings.judgements.get(i)[0], i);
		judgementsArray.sort(sortByJudgement);

		var curY:Float = (FlxG.height / 2) + 150;
		for (i in 0...judgementsArray.length)
		{
			var counter:JudgementCounter = new JudgementCounter(FlxG.width - 65, curY, judgementsArray[i]);
			add(counter);
			curY -= 65;
		}
	}

	private function sortByJudgement(Obj1:String, Obj2:String)
		return FlxSort.byValues(FlxSort.DESCENDING, Ratings.judgements.get(Obj1)[0], Ratings.judgements.get(Obj2)[0]);

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		accuracyText.text = 'Accuracy ${Math.floor(Ratings.accuracy * 100) / 100}%';
		timeBar.value = FlxMath.lerp((Conductor.songPosition / Conductor.boundSong.audioLength), timeBar.value, 0.95);
	}
}
