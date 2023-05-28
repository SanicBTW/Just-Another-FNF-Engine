package funkin;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class UI extends FlxSpriteGroup
{
	public var textFormat:String = "Score $score\nAccuracy $accuracy\nRank $rank$fc";

	public var scoreText:FlxText;

	public function new()
	{
		super();

		scoreText = new FlxText(30, (FlxG.height / 2) + (FlxG.height / 4), FlxG.width, '', 32);
		scoreText.font = Paths.font('vcr.ttf');
		scoreText.alignment = LEFT;
		scoreText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
		scoreText.y -= 50;
		add(scoreText);

		updateText();
	}

	public function updateText()
	{
		var fcDisplay:String = (Timings.ratingFC != null ? ' | [${Timings.ratingFC}]' : '');
		scoreText.text = textFormat.replace("$score", '${Timings.score}')
			.replace("$accuracy", '${Timings.getAccuracy()}')
			.replace("$rank", Timings.ratingName)
			.replace("$fc", fcDisplay)
			.replace("$misses", '${Timings.misses}');
	}
}
