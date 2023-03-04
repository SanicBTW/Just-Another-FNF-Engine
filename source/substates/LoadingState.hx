package substates;

import base.ScriptableState;
import base.pocketbase.Collections.PocketBaseObject;
import base.pocketbase.Request;
import base.ui.Alphabet;
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
	var infoShit:FlxTypedGroup<Alphabet>;
	var curLoading:Alphabet;

	override public function new(collection:String, pbObject:PocketBaseObject)
	{
		super();

		this.collection = collection;
		this.pbObject = pbObject;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		infoShit = new FlxTypedGroup<Alphabet>();
		add(infoShit);

		var main:Alphabet = new Alphabet(0, 0, "Loading", true, false);
		main.screenCenter();
		main.isMenuItem = false;
		main.alpha = 0;
		infoShit.add(main);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(main, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut});

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override public function create()
	{
		super.create();

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
		});
	}
}
