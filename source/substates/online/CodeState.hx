package substates.online;

import base.ScriptableState.ScriptableSubState;
import base.ScriptableState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxInputText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import states.online.ConnectingState;

class CodeState extends ScriptableSubState
{
	private var txtInput:FlxInputText;

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		txtInput = new FlxInputText(0, 0, 150, "", 24);
		txtInput.alpha = 0;
		txtInput.screenCenter();
		add(txtInput);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(txtInput, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut});
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (action == "confirm")
		{
			if (txtInput.text == "")
				close();

			ScriptableState.switchState(new ConnectingState('join', txtInput.text));
		}

		if (action == "back")
		{
			close();
		}
	}
}
