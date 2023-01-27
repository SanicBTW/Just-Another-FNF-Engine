package states;

import base.Alphabet;
import base.Controls;
import base.SaveData;
import base.ScriptableState;
import base.pocketbase.Collections.Funkin;
import base.pocketbase.Collections.Funkin_Old;
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

class MainState extends ScriptableState
{
	var pages:Array<String> = ["funkin", "old_fnf_charts", "osu!", "quaver", "settings"];
	var curPage(default, set):Int = 0;
	var grpItems:FlxTypedGroup<Alphabet>;
	var menuArray:Array<String> = [];
	var songDetails:Map<String, PocketBaseObject> = [];
	var curSelected(default, set):Int = 0;

	private function set_curSelected(value:Int):Int
	{
		curSelected += value;

		if (curSelected < 0)
			curSelected = menuArray.length - 1;
		if (curSelected >= menuArray.length)
			curSelected = 0;

		var tf:Int = 0;

		for (item in grpItems.members)
		{
			item.targetY = tf - curSelected;
			tf++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}

		return curSelected;
	}

	private function set_curPage(value:Int):Int
	{
		curPage += value;

		if (curPage < 0)
			curPage = pages.length - 1;
		if (curPage >= pages.length)
			curPage = 0;

		if (pages[curPage] == "funkin" || pages[curPage] == "old_fnf_charts")
		{
			var isOld:Bool = (pages[curPage] == "old_fnf_charts");
			Request.getRecords(pages[curPage], function(data:String)
			{
				menuArray = [];

				var songShit:Array<Funkin & Funkin_Old> = cast Json.parse(data).items;
				for (song in songShit)
				{
					songDetails.set((isOld ? song.song_name : song.song),
						new PocketBaseObject(song.id, (isOld ? song.song_name : song.song), (isOld ? song.chart_file : song.chart), song.inst, song.voices));
					menuArray.push((isOld ? song.song_name : song.song));
				}
				regenMenu();
			});
		}

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

		grpItems = new FlxTypedGroup<Alphabet>();
		add(grpItems);

		curPage = 0;

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
				curSelected = -1;
			case "ui_down":
				curSelected = 1;
			case "ui_left":
				curPage = -1;
			case "ui_right":
				curPage = 1;
			case "confirm":
				{
					if (pages[curPage] == "funkin" || pages[curPage] == "old_fnf_charts")
					{
						var pbObject:PocketBaseObject = songDetails.get(menuArray[curSelected]);
						persistentUpdate = false;
						blockInputs = true;

						Request.getFile(pages[curPage], pbObject.id, pbObject.chart, function(chart)
						{
							ChartLoader.netChart = chart;

							Request.getSound(pages[curPage], pbObject.id, pbObject.inst, function(sound)
							{
								ChartLoader.netInst = sound;
							});

							if (pbObject.voices != "")
							{
								Request.getSound(pages[curPage], pbObject.id, pbObject.voices, function(sound)
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
	}

	private function regenMenu()
	{
		for (i in 0...grpItems.members.length)
		{
			grpItems.remove(grpItems.members[0], true);
		}
		for (i in 0...menuArray.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuArray[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpItems.add(songText);
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
		curSelected = 0;
	}
}
