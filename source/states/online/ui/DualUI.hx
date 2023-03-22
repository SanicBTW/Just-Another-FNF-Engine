package states.online.ui;

import base.system.Conductor;
import base.ui.Bar;
import base.ui.Fonts;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import states.online.ConnectingState.PlayerData;

class DualUI extends FlxSpriteGroup
{
	// shits gonna blow up fr
	private var accuracy1Text:FlxBitmapText;
	private var score1Text:FlxBitmapText;
	private var misses1Text:FlxBitmapText;

	private var accuracy2Text:FlxBitmapText;
	private var score2Text:FlxBitmapText;
	private var misses2Text:FlxBitmapText;

	public function new()
	{
		super();

		setupP1();
		add(accuracy1Text);
		add(score1Text);
		add(misses1Text);
		setupP2();
		add(accuracy2Text);
		add(score2Text);
		add(misses2Text);
	}

	private function setupP1()
	{
		accuracy1Text = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(accuracy1Text);
		accuracy1Text.setPosition(30, (FlxG.height / 2) + (FlxG.height / 4));
		accuracy1Text.text = "Accuracy 0%";

		score1Text = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(score1Text);
		score1Text.setPosition(30, ((accuracy1Text.y + accuracy1Text.height) - (accuracy1Text.height / 2)));
		score1Text.text = "Score 0";

		misses1Text = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(misses1Text);
		misses1Text.setPosition(30, ((accuracy1Text.y - accuracy1Text.height) + (accuracy1Text.height / 2)));
		misses1Text.text = "Misses 0";
	}

	private function setupP2()
	{
		accuracy2Text = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(accuracy2Text);
		accuracy2Text.setPosition(30, (FlxG.height / 2) - (FlxG.height / 4));
		accuracy2Text.text = "Accuracy 0%";

		score2Text = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(score2Text);
		score2Text.setPosition(30, ((accuracy2Text.y + accuracy2Text.height) - (accuracy2Text.height / 2)));
		score2Text.text = "Score 0";

		misses2Text = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(misses2Text);
		misses2Text.setPosition(30, ((accuracy2Text.y - accuracy2Text.height) + (accuracy2Text.height / 2)));
		misses2Text.text = "Misses 0";
	}

	public function updateStats(p1:PlayerData, p2:PlayerData)
	{
		accuracy1Text.text = 'Accuracy ${p1.accuracy}%';
		score1Text.text = 'Score ${p1.score}';
		misses1Text.text = 'Misses ${p1.misses}';

		accuracy2Text.text = 'Accuracy ${p2.accuracy}%';
		score2Text.text = 'Score ${p2.score}';
		misses2Text.text = 'Misses ${p2.misses}';
	}
}
