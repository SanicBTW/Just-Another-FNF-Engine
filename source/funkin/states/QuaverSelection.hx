package funkin.states;

import backend.Conductor;
import backend.DiscordPresence;
import base.MusicBeatState;
import base.TransitionState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import funkin.text.Alphabet;
import quaver.*;

class QuaverSelection extends MusicBeatState
{
	private var store:Map<String, String> = new Map();
	private var diffStore:Map<String, String> = new Map();

	public static var mapID:String;

	private var curSelected(default, set):Int = 0;

	@:noCompletion
	private function set_curSelected(value:Int):Int
	{
		curSelected += value;

		if (curSelected < 0)
			curSelected = grpOptions.members.length - 1;
		if (curSelected >= grpOptions.members.length)
			curSelected = 0;

		var tf:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = tf - curSelected;
			tf++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}

		return curSelected;
	}

	private var curText(get, null):String;

	@:noCompletion
	private function get_curText():String
		return (grpOptions.members[curSelected] != null ? grpOptions.members[curSelected].text : "");

	private var grpOptions:FlxTypedGroup<Alphabet>;

	private var curSState:String = "NameList";
	private var blockInputs = false;

	override public function create()
	{
		FlxG.sound.playMusic(Paths.music("freakyMenu"));
		Conductor.changeBPM(102, false);

		var darkBackground:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		darkBackground.setGraphicSize(Std.int(FlxG.width));
		darkBackground.screenCenter();
		darkBackground.alpha = 0.7;
		add(darkBackground);

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.image('smenuBG'));
		bg.setGraphicSize(FlxG.width);
		bg.screenCenter();
		bg.blend = openfl.display.BlendMode.DIFFERENCE;
		bg.alpha = 0.07;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		DiscordPresence.changePresence("Selecting Quaver Beatmap");

		var maps:Array<String> = [];
		// ??? It gives me nulls now, probably because of the async shit i made
		try
		{
			for (MapSetId in QuaverDB.availableMaps.keys())
			{
				var firstID:String = QuaverDB.availableMaps.get(MapSetId)[0];
				var qua:Qua = QuaverDB.loadedMaps.get(firstID);
				store.set(qua.Title, MapSetId);
				maps.push(qua.Title);
			}
		}
		catch (ex)
		{
			maps.push("Failed to load beatmaps");
			trace(ex);
		}

		regenMenu(maps);

		super.create();
	}

	override function onActionPressed(action:String)
	{
		if (blockInputs)
			return;

		switch (action)
		{
			case "ui_up":
				curSelected = -1;
			case "ui_down":
				curSelected = 1;

			case "confirm":
				{
					blockInputs = true;

					switch (curSState)
					{
						case "NameList":
							{
								var diffs:Array<String> = [];
								for (MapId in QuaverDB.availableMaps.get(store.get(curText)))
								{
									var qua:Qua = QuaverDB.loadedMaps.get(MapId);
									diffs.push(qua.DifficultyName);
									diffStore.set(qua.DifficultyName, '${qua.MapId}');
								}
								regenMenu(diffs);
								curSState = "DiffList";
							}

						case "DiffList":
							{
								mapID = diffStore.get(curText);
								TransitionState.switchState(new QuaverGameplay());
							}
					}
				}

			case "back":
				{
					blockInputs = true;

					switch (curSState)
					{
						case "NameList":
							{
								TransitionState.switchState(new SongSelection());
							}

						case "DiffList":
							{
								var maps:Array<String> = [];
								for (title in store.keys()) // smartass wanted to do all the loop based on QuaverDB again :skull:
								{
									maps.push(title);
								}

								curSState = "NameList";
								regenMenu(maps);
							}
					}
				}
		}
	}

	override function onActionReleased(action:String)
	{
		blockInputs = false;
	}

	private function regenMenu(array:Array<String>)
	{
		for (i in 0...grpOptions.members.length)
		{
			grpOptions.remove(grpOptions.members[0], true);
		}

		for (i in 0...array.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, array[i], true);
			songText.isMenuItem = true;
			songText.targetY = i - curSelected;
			grpOptions.add(songText);

			var maxWidth:Float = 980;
			if (songText.width > 980)
			{
				songText.scaleX = maxWidth / songText.width;
			}
		}
		curSelected = grpOptions.length + 1;
	}
}