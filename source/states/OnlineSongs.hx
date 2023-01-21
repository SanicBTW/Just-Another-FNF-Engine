package states;

import base.Alphabet;
import base.Controls;
import base.SaveData;
import base.ScriptableState;
import base.pocketbase.Collections.PocketBaseObject;
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
	var collections:Array<String> = ["funkin", "old_fnf_charts"];
	var curColl(default, set):Int = 0;
	var grpSongs:FlxTypedGroup<Alphabet>;
	var songArray:Array<String> = [];
	var songDetails:Map<String, Array<String>> = [];
	var curSelected:Int = 0;

	private function set_curColl(value:Int):Int
	{
		return value;
	}

	override public function create()
	{
		Controls.setActions(UI);
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
				songDetails.set(song.song, [song.id, song.chart, song.inst, song.voices]);
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
					Request.getFile(collections[curColl], details[0], details[1], function(data)
					{
						ChartLoader.netChart = data;
						Request.getSound(collections[curColl], details[0], details[2], function(sound)
						{
							ChartLoader.netInst = sound;
						});

						if (details[2] != "")
						{
							Request.getSound(collections[curColl], details[0], details[3], function(sound)
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

	function changeCollection(change:Int = 0)
	{
		curColl += change;

		if (curColl < 0)
			curColl = collections.length - 1;
		if (curColl >= collections.length)
			curColl = 0;
	}

	private function regenMenu()
	{
		for (i in 0...grpSongs.members.length)
		{
			grpSongs.remove(grpSongs.members[0], true);
		}
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
