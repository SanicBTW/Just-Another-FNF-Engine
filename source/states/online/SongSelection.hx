package states.online;

import base.MusicBeatState;
import base.ScriptableState;
import base.pocketbase.Collections.Funkin as FunkCollection;
import base.pocketbase.Collections.PocketBaseObject;
import base.pocketbase.Request;
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

		if (receivedPB != null)
		{
			doRequest(receivedPB);
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
					room.send('set_song', {songObj: Json.stringify(pbObject)});
					doRequest(pbObject);
				}
		}
	}

	function doRequest(pbObject:PocketBaseObject)
	{
		canPress = false;

		var overlay:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		overlay.alpha = 0.7;
		add(overlay);

		room.send('report_status', 'Loading chart');
		Request.getFile("funkin", pbObject.id, pbObject.chart, false, (chart:String) ->
		{
			ChartLoader.netChart = chart;
			room.send('report_status', 'Loading inst');

			Request.getFile("funkin", pbObject.id, pbObject.inst, true, (inst:Sound) ->
			{
				ChartLoader.netInst = inst;
				room.send('report_status', 'Checking voices');

				if (pbObject.voices != "")
				{
					room.send('report_status', 'Loading voices');
					Request.getFile("funkin", pbObject.id, pbObject.voices, true, (voices:Sound) ->
					{
						room.send('report_status', 'Waiting');
						ChartLoader.netVoices = voices;
						ScriptableState.switchState(new LobbyState());
					});
				}
				else
				{
					room.send('report_status', 'Waiting');
					ChartLoader.netVoices = null;
					ScriptableState.switchState(new LobbyState());
				}
			});
		});
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
