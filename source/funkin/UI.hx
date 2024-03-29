package funkin;

import backend.Conductor;
import base.sprites.*;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.*;
import funkin.components.JudgementCounter;

using StringTools;

@:publicFields
class UI extends FlxSpriteGroup
{
	var textFormat:String = "Score $score\nAccuracy $accuracy\nRank $rank$fc";
	var fcFormat:String = " | [fc]";
	var judgementOffset:Array<Float> = [0, 0]; // Soon will be moved to Settings

	var scoreText:FlxText;

	var judgementGroup:FlxTypedSpriteGroup<DepthSprite>;
	var comboGroup:FlxTypedSpriteGroup<DepthSprite>;
	var countersGroup:FlxTypedSpriteGroup<JudgementCounter>;

	public function new()
	{
		super();

		var separation:Float = (FlxG.height / 4);

		scoreText = new FlxText(30, (Settings.downScroll ? (FlxG.height / 2) - separation : (FlxG.height / 2) + separation), FlxG.width, formatText(), 32);
		scoreText.font = Paths.font('vcr.ttf');
		scoreText.alignment = LEFT;
		scoreText.autoSize = false;
		scoreText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
		scoreText.y -= 50;
		add(scoreText);

		add(judgementGroup = new FlxTypedSpriteGroup<DepthSprite>());
		add(comboGroup = new FlxTypedSpriteGroup<DepthSprite>());
		add(countersGroup = new FlxTypedSpriteGroup<JudgementCounter>());

		refreshCounters();

		displayJudgement('sick', false, true);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		scoreText.text = formatText();
	}

	public function refreshCounters(startingPos:Null<Int> = null)
	{
		if (!Settings.showJudgementCounters)
			return;

		if (startingPos == null)
			startingPos = FlxG.width;

		if (countersGroup.length > 0)
		{
			for (i in 0...countersGroup.members.length)
			{
				countersGroup.remove(countersGroup.members[0], true).destroy();
			}
		}

		var padding:Null<Float> = 20;

		var judgementsArray:Array<Judgement> = [];
		for (idx => judge in Timings.judgements)
			judgementsArray.insert(idx, judge);
		judgementsArray.sort(sortJudgements);

		var pre:JudgementCounter = new JudgementCounter(0, 0, judgementsArray[0]);
		var th:Null<Float> = judgementsArray.length * (pre.height + padding) - padding; // total height
		var sy:Null<Float> = (FlxG.height - th) / 2; // start y

		pre.destroy();
		pre = null;

		for (idx => judge in judgementsArray)
		{
			var counter:JudgementCounter = new JudgementCounter(0, 0, judge);
			counter.x = startingPos - (counter.width + padding);

			if (idx == judgementsArray.length / 2)
				counter.y = (FlxG.height / 2);
			else
				counter.y = sy + idx * (counter.height + padding);

			countersGroup.add(counter);
		}

		// mark as gc - only on mark & sweep gc dummy
		padding = th = sy = null;
		judgementsArray = null;
	}

	public function formatText():String
	{
		var fcDisplay:String = (Timings.ratingFC != null ? fcFormat.replace("fc", Timings.ratingFC) : '');
		return textFormat.replace("$score", '${Timings.score}')
			.replace("$accuracy", Timings.getAccuracy())
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

		curJudgement.z = -Conductor.time;
		if (perfect || preload)
			curJudgement.animation.play('sick-perfect');
		else
			curJudgement.animation.play(judgement + (late ? '-late' : '-early'));

		curJudgement.setGraphicSize(Std.int(curJudgement.frameWidth * 0.7));

		curJudgement.acceleration.y = 550;
		curJudgement.velocity.x = -FlxG.random.int(0, 10);
		curJudgement.velocity.y = -FlxG.random.int(140, 175);

		curJudgement.screenCenter();
		curJudgement.x = ((FlxG.width * 0.35) - 40) - judgementOffset[0];
		curJudgement.y -= 60 + judgementOffset[1];

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

			combo.z = -Conductor.time;
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

	private function sortJudgements(Obj1:Judgement, Obj2:Judgement)
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Timings.getJudgementIndex(Obj1.name), Timings.getJudgementIndex(Obj2.name));
	}
}
