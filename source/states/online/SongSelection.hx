package states.online;

import base.MusicBeatState;
import base.ScriptableState;
import base.pocketbase.Collections.Funkin as FunkCollection;
import base.pocketbase.Collections.PocketBaseObject;
import base.pocketbase.Request;
import base.system.DiscordPresence;
import base.ui.Alphabet;
import base.ui.CircularSprite.CircularSpriteText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import funkin.ChartLoader;
import haxe.Json;
import io.colyseus.Room;
import openfl.media.Sound;
import states.online.schema.VersusRoom;
import substates.online.OnlineLoadingState;

class SongSelection extends MusicBeatState
{
	public static var room:Room<VersusRoom>;

	private var curOption(default, set):Int = 0;
	private var curOptionStr:String;
	private var groupItems:FlxTypedGroup<Alphabet>;
	private var songStore:Map<String, PocketBaseObject> = new Map();
	private var canPress:Bool = true;

	private var receivedPB:PocketBaseObject;

	private function set_curOption(value:Int):Int
	{
		curOption += value;

		if (curOption < 0)
			curOption = groupItems.members.length - 1;
		if (curOption >= groupItems.members.length)
			curOption = 0;

		var tf:Int = 0;

		for (item in groupItems.members)
		{
			item.targetY = tf - curOption;
			tf++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}

		if (groupItems.members[curOption] != null)
			curOptionStr = groupItems.members[curOption].text;

		return curOption;
	}

	public function new(?pbObject:PocketBaseObject)
	{
		super();

		if (pbObject != null)
			this.receivedPB = pbObject;
	}

	override public function create()
	{
		groupItems = new FlxTypedGroup<Alphabet>();
		add(groupItems);

		super.create();

		DiscordPresence.changePresence("Selecting a song");

		if (receivedPB != null)
		{
			canPress = false;
			openSubState(new OnlineLoadingState("funkin", receivedPB));
			return;
		}

		Request.getRecords("funkin", (data:String) ->
		{
			if (data == "Failed to fetch")
			{
				regenMenu(["Failed to fetch"]);
				return;
			}

			var regenArray:Array<String> = [];
			var songShit:Array<FunkCollection> = cast Json.parse(data).items;
			for (i in 0...songShit.length)
			{
				var song = songShit[i];
				songStore.set(song.song, new PocketBaseObject(song.id, song.song, song.chart, song.inst, song.voices));
				regenArray.push(song.song);
			}
			regenMenu(regenArray);
		});
	}

	override function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (!canPress)
			return;

		switch (action)
		{
			case "back":
				room.leave();
				ScriptableState.switchState(new AlphabetMenu());
			case "ui_up":
				curOption = -1;
			case "ui_down":
				curOption = 1;
			case "confirm":
				{
					if (curOptionStr == "Failed to fetch")
						return;

					var pbObject:PocketBaseObject = songStore.get(curOptionStr);
					room.send('set_song', {
						songObj: {
							id: pbObject.id,
							song: pbObject.song,
							chart: pbObject.chart,
							inst: pbObject.inst,
							voices: pbObject.voices
						}
					});
					canPress = false;
					openSubState(new OnlineLoadingState("funkin", pbObject));
				}
		}
	}

	private function regenMenu(array:Array<String>)
	{
		for (i in 0...groupItems.members.length)
		{
			groupItems.remove(groupItems.members[0], true);
		}
		for (i in 0...array.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, array[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			groupItems.add(songText);
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
		curOption = groupItems.length + 1;
	}
}
