package substates;

import base.ScriptableState;
import base.pocketbase.Collections.PocketBaseObject;
import base.pocketbase.MultiCallback;
import base.pocketbase.Request;
import base.system.DiscordPresence;
import base.ui.Bar;
import base.ui.Fonts;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.ChartLoader;
import openfl.media.Sound;
import states.PlayTest;

using StringTools;

class LoadingState extends ScriptableSubState
{
	private var collection:String;
	private var pbObject:PocketBaseObject;

	private var loadingBar:Bar;
	private var tracking:FlxBitmapText;

	private var callbacks:MultiCallback = new MultiCallback(() ->
	{
		ScriptableState.switchState(new PlayTest());
	});

	override public function new(collection:String, pbObject:PocketBaseObject)
	{
		super();

		this.collection = collection;
		this.pbObject = pbObject;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		loadingBar = new Bar(0, 0, FlxG.width - 50, 10, FlxColor.fromRGB(30, 144, 255), FlxColor.WHITE);
		loadingBar.screenCenter();
		loadingBar.y = FlxG.height - 20;
		loadingBar.screenCenter(X);
		loadingBar.alpha = 0;
		// stupid ass fix
		loadingBar.flipX = true;
		add(loadingBar);

		var loadingHeader:FlxBitmapText = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(loadingHeader, true, 0.5);
		loadingHeader.text = "Loading...";
		loadingHeader.setPosition(30, (FlxG.height / 2) - (FlxG.height / 4));
		loadingHeader.alpha = 0;
		add(loadingHeader);

		tracking = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(tracking, true, 0.5);
		tracking.text = "Chart";
		tracking.setPosition(30, ((loadingHeader.y + loadingHeader.height) - (loadingHeader.height / 2)));
		tracking.alpha = 0;
		add(tracking);

		var funny:FlxSprite = new FlxSprite().loadGraphic(Paths.image("animan"));
		funny.antialiasing = SaveData.antialiasing;
		funny.setGraphicSize(640, 640);
		funny.screenCenter();
		funny.x += 150;
		funny.alpha = 0;
		add(funny);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(loadingBar, {alpha: 0.9}, 0.5, {ease: FlxEase.quartInOut});
		FlxTween.tween(loadingHeader, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut});
		FlxTween.tween(tracking, {alpha: 1}, 0.5, {ease: FlxEase.quartInOut});
		FlxTween.tween(funny, {alpha: 1}, 0.6, {ease: FlxEase.quartInOut});
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var lerpVal:Float = funkin.CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1);

		loadingBar.value = FlxMath.lerp((callbacks.numRemaining / callbacks.length), loadingBar.value, lerpVal);
	}

	override public function create()
	{
		super.create();

		var chartCb:() -> Void = callbacks.add("Chart:" + pbObject.id);
		var instCb:() -> Void = callbacks.add("Inst:" + pbObject.id);
		var voicesCb:() -> Void = callbacks.add("Voices:" + pbObject.id);

		DiscordPresence.changePresence('Loading ${pbObject.song}', "Chart");
		Request.getFile(collection, pbObject.id, pbObject.chart, false, (chart:String) ->
		{
			ChartLoader.netChart = chart;
			chartCb();
			tracking.text = "Inst";
			DiscordPresence.changePresence('Loading ${pbObject.song}', "Inst");

			Request.getFile(collection, pbObject.id, pbObject.inst, true, (inst:Sound) ->
			{
				ChartLoader.netInst = inst;
				instCb();
				tracking.text = "Checking";
				DiscordPresence.changePresence('Loading ${pbObject.song}', "Checking voices");

				if (pbObject.voices != "")
				{
					tracking.text = "Voices";
					DiscordPresence.changePresence('Loading ${pbObject.song}', "Voices");
					Request.getFile(collection, pbObject.id, pbObject.voices, true, (voices:Sound) ->
					{
						ChartLoader.netVoices = voices;
						tracking.text = "Done!";
						voicesCb();
					});
				}
				else
				{
					ChartLoader.netVoices = null;
					tracking.text = "Done!";
					voicesCb();
				}
			});
		});
	}
}
