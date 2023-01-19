package states;

import base.Alphabet;
import base.SaveData;
import base.ScriptableState;
import base.pocketbase.Request;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import funkin.ChartLoader;
import haxe.Json;
import openfl.media.Sound;

using StringTools;

class OnlineSongs extends ScriptableState
{
	var currentCollection:String = "funkin";
	var grpSongs:FlxTypedGroup<Alphabet>;
	var songArray:Array<String> = [];
	var songDetails:Map<String, Array<String>> = [];
	var curSelected:Int = 0;

	override public function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuSDefault"));
		bg.screenCenter();
		bg.antialiasing = SaveData.antialiasing;
		bg.alpha = 0.5;
		bg.color = FlxColor.CYAN;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		Request.getRecords("funkin", function(data:String)
		{
			var songShit:Array<base.pocketbase.Collections.Funkin> = cast Json.parse(data).items;
			for (song in songShit)
			{
				var id:String = Request.filesExt.replace(":id", song.id).replace(":col", currentCollection);
				var chart:String = Request.base + id.replace(":file", song.chart);
				var inst:String = Request.base + id.replace(":file", song.inst);
				var voices:String = "";
				if (song.voices != "")
					voices = Request.base + id.replace(":file", song.voices);

				songDetails.set(song.song, [chart, inst, voices]);
				songArray.push(song.song);
			}
			regenMenu();
		});

		super.create();
	}

	private var blockInputs = false;

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (blockInputs == true)
			return;

		switch (action)
		{
			case "ui_up":
				changeSelection(-1);
			case "ui_down":
				changeSelection(1);
			case "confirm":
				{
					var details:Array<String> = songDetails.get(songArray[curSelected]);
					persistentUpdate = false;
					blockInputs = true;
					Request.get(details[0], function(data)
					{
						ChartLoader.netChart = data;
						Sound.loadFromFile(details[1]).onComplete(function(sound)
						{
							ChartLoader.netInst = sound;
						});

						if (details[2] != "")
						{
							Sound.loadFromFile(details[2]).onComplete(function(sound)
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
				}
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = songArray.length - 1;
		if (curSelected >= songArray.length)
			curSelected = 0;

		var tf:Int = 0;

		for (item in grpSongs.members)
		{
			item.targetY = tf - curSelected;
			tf++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}
	}

	private function regenMenu()
	{
		for (i in 0...songArray.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songArray[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			if (songText.width > 980)
			{
				var textScale:Float = 980 / songText.width;
				songText.scale.x = textScale;
				for (letter in songText.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
			}
		}
		changeSelection(0);
	}
}
