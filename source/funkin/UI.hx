package funkin;

import base.Conductor;
import base.sprites.DepthSprite;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;

using StringTools;

@:publicFields
class UI extends FlxSpriteGroup
{
	var textFormat:String = "Score $score\nAccuracy $accuracy\nRank $rank$fc";

	var scoreText:FlxText;

	var judgementGroup:FlxTypedSpriteGroup<DepthSprite>;
	var comboGroup:FlxTypedSpriteGroup<DepthSprite>;

	public function new()
	{
		super();

		scoreText = new FlxText(30, (FlxG.height / 2) + (FlxG.height / 4), FlxG.width, formatText(), 32);
		scoreText.font = Paths.font('vcr.ttf');
		scoreText.alignment = LEFT;
		scoreText.autoSize = false;
		scoreText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
		scoreText.y -= 50;
		add(scoreText);

		judgementGroup = new FlxTypedSpriteGroup<DepthSprite>();
		comboGroup = new FlxTypedSpriteGroup<DepthSprite>();
		add(judgementGroup);
		add(comboGroup);

		displayJudgement('sick', false, true);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		scoreText.text = formatText();
	}

	public function formatText():String
	{
		var fcDisplay:String = (Timings.ratingFC != null ? ' | [${Timings.ratingFC}]' : '');
		return textFormat.replace("$score", '${Timings.score}')
			.replace("$accuracy", '${Timings.getAccuracy()}')
			.replace("$rank", Timings.ratingName)
			.replace("$fc", fcDisplay)
			.replace("$misses", '${Timings.misses}');
	}

	public function displayJudgement(judgement:String, late:Bool, preload:Bool = false)
	{
		var perfect:Bool = Timings.ratingFC != null && Timings.ratingFC == "SFC";

		var curJudgement:DepthSprite = judgementGroup.recycle(DepthSprite, function()
		{
			var newJudgement:DepthSprite = new DepthSprite();
			newJudgement.loadGraphic(Paths.image('ui/judgements'), true, 500, 163);
			newJudgement.animation.add('sick-perfect', [0]);
			for (i in 0...Timings.judgements.length)
			{
				for (j in 0...2)
					newJudgement.animation.add(Timings.judgements[i].name + (j == 1 ? '-late' : '-early'), [(i * 2) + (j == 1 ? 1 : 0) + 2]);
			}

			return newJudgement;
		});

		curJudgement.alpha = (preload) ? 0 : 1;

		curJudgement.z = -Conductor.songPosition;
		curJudgement.animation.play(judgement + (late ? '-late' : '-early'));
		if (perfect)
			curJudgement.animation.play('sick-perfect');

		curJudgement.setGraphicSize(Std.int(curJudgement.frameWidth * 0.7));

		curJudgement.acceleration.y = 550;
		curJudgement.velocity.x = -FlxG.random.int(0, 10);
		curJudgement.velocity.y = -FlxG.random.int(140, 175);

		curJudgement.screenCenter();
		curJudgement.x = (FlxG.width * 0.35) - 40;
		curJudgement.y -= 60;

		judgementGroup.add(curJudgement);

		if (preload)
			curJudgement.kill();
		else
		{
			FlxTween.tween(curJudgement, {alpha: 0}, (Conductor.stepCrochet) / 1000, {
				onComplete: function(_)
				{
					curJudgement.kill();
				},
				startDelay: ((Conductor.crochet + Conductor.stepCrochet * 2) / 1000)
			});
		}

		var comboString:String = Std.string(Timings.combo);
		var stringArray:Array<String> = comboString.split("");
		for (i in 0...stringArray.length)
		{
			var combo:DepthSprite = comboGroup.recycle(DepthSprite, function()
			{
				var newCombo:DepthSprite = new DepthSprite();
				newCombo.loadGraphic(Paths.image('ui/combo'), true, 100, 140);
				newCombo.animation.add('-', [0]);
				for (i in 0...10)
				{
					newCombo.animation.add('$i', [(i + 1)], 0, false);
					newCombo.animation.add('$i-perfect', [(i + 1) + 11], 0, false);
				}
				return newCombo;
			});

			combo.alpha = (preload) ? 0 : 1;

			combo.z = -Conductor.songPosition;
			combo.animation.play(stringArray[i]);
			if (perfect)
				combo.animation.play(stringArray[i] + "-perfect");

			combo.setGraphicSize(Std.int(combo.frameWidth * 0.5));

			combo.acceleration.y = curJudgement.acceleration.y - FlxG.random.int(100, 200);
			combo.velocity.x = FlxG.random.float(-5, 5);
			combo.velocity.y = -FlxG.random.int(140, 160);

			combo.x = curJudgement.x + (curJudgement.width * (1 / 2)) + (43 * i);
			combo.y = curJudgement.y + curJudgement.height / 2;

			comboGroup.add(combo);

			if (preload)
				combo.kill();
			else
			{
				FlxTween.tween(combo, {alpha: 0}, (Conductor.stepCrochet * 2) / 1000, {
					onComplete: function(tween:FlxTween)
					{
						combo.kill();
					},
					startDelay: (Conductor.crochet) / 1000
				});
			}
		}

		judgementGroup.sort(DepthSprite.depthSorting, FlxSort.DESCENDING);
		comboGroup.sort(DepthSprite.depthSorting, FlxSort.DESCENDING);
	}
}
