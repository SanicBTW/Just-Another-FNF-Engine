package states;

import base.MusicBeatState;
import base.ScriptableState;
import base.pocketbase.Collections.Funkin;
import base.pocketbase.Collections.Funkin_Old;
import base.pocketbase.Collections.PocketBaseObject;
import base.pocketbase.Request;
import base.system.Conductor;
import base.system.Controls;
import base.system.SoundManager;
import base.ui.Alphabet;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.Json;
import lime.utils.Assets;
import states.config.EarlyConfig;
import states.config.KeybindsState;
import substates.LoadingState;

using StringTools;

class MainState extends MusicBeatState
{
	var pages:Array<String> = ["internal", "funkin", "old_fnf_charts", "settings"];
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

		switch (pages[curPage])
		{
			case "internal":
				{
					var shitShow:Array<String> = Assets.getLibrary("songs").list("TEXT");
					for (shit in 0...shitShow.length)
					{
						shitShow[shit] = shitShow[shit].replace("assets/songs/", "");
						shitShow[shit] = shitShow[shit].substring(shitShow[shit].lastIndexOf("/") + 1, shitShow[shit].indexOf("-"));
					}
					menuArray = shitShow;
					regenMenu();
				}
			case "funkin" | "old_fnf_charts":
				{
					var isOld:Bool = (pages[curPage] == "old_fnf_charts");
					Request.getRecords(pages[curPage], function(data:String)
					{
						menuArray = [];

						if (data == "Failed to fetch")
						{
							menuArray.push("NETWORK ERROR");
							regenMenu();
							return;
						}

						var songShit:Array<Funkin & Funkin_Old> = cast Json.parse(data).items;
						for (song in songShit)
						{
							songDetails.set((isOld ? song.song_name : song.song),
								new PocketBaseObject(song.id, (isOld ? song.song_name : song.song), (isOld ? song.chart_file : song.chart), song.inst,
									song.voices));
							menuArray.push((isOld ? song.song_name : song.song));
						}
						regenMenu();
					});
				}
			case "settings":
				{
					menuArray = ["Settings", "Keybinds"];
					regenMenu();
				}
		}

		return value;
	}

	override public function create()
	{
		Controls.setActions(UI);

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuSDefault2"));
		bg.screenCenter();
		bg.antialiasing = SaveData.antialiasing;
		bg.alpha = 0.5;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		add(bg);

		grpItems = new FlxTypedGroup<Alphabet>();
		add(grpItems);

		curPage = 0;

		super.create();

		Conductor.boundSong = bgMusic;
		Conductor.changeBPM(102);
		bgMusic.audioSource = Paths.music("freakyMenu");
		bgMusic.loopAudio = true;
		bgMusic.play();
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
					switch (pages[curPage])
					{
						case "internal":
							{
								bgMusic.stop();
								ScriptableState.switchState(new PlayTest(menuArray[curSelected]));
							}
						case "funkin" | "old_fnf_charts":
							{
								if (menuArray[curSelected] == "NETWORK ERROR")
									return;

								var pbObject:PocketBaseObject = songDetails.get(menuArray[curSelected]);
								persistentUpdate = false;
								blockInputs = true;
								bgMusic.stop();
								openSubState(new LoadingState(pages[curPage], pbObject));
							}
						case "settings":
							{
								ScriptableState.switchState((menuArray[curSelected] == "Settings") ? new EarlyConfig() : new KeybindsState());
							}
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
