package substates;

import base.ScriptableState;
import base.pocketbase.Collections.PocketBaseObject;
import base.pocketbase.Request;
import base.ui.Alphabet;
import base.ui.Bar;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.ChartLoader;
import states.PlayTest;

using StringTools;

// TODO: improve the usage of tweens and the position
class LoadingState extends ScriptableSubState
{
	var collection:String;
	var pbObject:PocketBaseObject;

	var loadingBar:Bar;

	override public function new(collection:String, pbObject:PocketBaseObject)
	{
		super();

		this.collection = collection;
		this.pbObject = pbObject;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		loadingBar = new Bar(0, 0, FlxG.width - 50, 10, FlxColor.WHITE, FlxColor.fromRGB(30, 144, 255));
		loadingBar.screenCenter();
		loadingBar.y = FlxG.height - 20;
		loadingBar.screenCenter(X);
		add(loadingBar);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
	}

	override public function create()
	{
		super.create();

		/*
			curLoading = new Alphabet(0, 0, "Chart", true, false);
			curLoading.screenCenter();
			curLoading.isMenuItem = false;
			curLoading.alpha = 0;
			infoShit.add(curLoading);

			FlxTween.tween(infoShit.members[0], {y: infoShit.members[0].y - (curLoading.height + 10)}, 1, {ease: FlxEase.quartInOut});
			FlxTween.tween(curLoading, {alpha: 1}, 1, {ease: FlxEase.quartInOut});

			Request.getFile(collection, pbObject.id, pbObject.chart, function(chart)
			{
				ChartLoader.netChart = chart;

				curLoading.changeText("Inst");
				Request.getSound(collection, pbObject.id, pbObject.inst, function(sound)
				{
					ChartLoader.netInst = sound;
					if (pbObject.voices != "")
					{
						curLoading.changeText("Voices");
						Request.getSound(collection, pbObject.id, pbObject.voices, function(sound)
						{
							ChartLoader.netVoices = sound;
							ScriptableState.switchState(new PlayTest());
						});
					}
					else
					{
						ChartLoader.netVoices = null;
						ScriptableState.switchState(new PlayTest());
					}
				});
		});*/
	}
}
