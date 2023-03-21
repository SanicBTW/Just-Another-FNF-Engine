package states.online;

import base.MusicBeatState;
import base.ScriptableState;
import base.pocketbase.Collections.Funkin as FunkCollection;
import base.pocketbase.Collections.PocketBaseObject;
import base.pocketbase.Request;
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
	private var groupItems:FlxTypedGroup<CircularSpriteText>;
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

		var the:Int = 0;

		for (item in groupItems)
		{
			item.selected = (item.ID == curOption);

			if (item.menuItem)
			{
				item.targetY = the - curOption;
				the++;
			}
		}

		if (groupItems.members[curOption] != null)
			curOptionStr = groupItems.members[curOption].bitmapText.text;

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
		groupItems = new FlxTypedGroup<CircularSpriteText>();
		add(groupItems);

		super.create();

		if (receivedPB != null)
		{
			doRequest(receivedPB);
			return;
		}

		var req:Request = Request.getRecords("funkin");
		req.onSuccess.add((data:String) ->
		{
			var songShit:Array<FunkCollection> = cast Json.parse(data).items;
			for (i in 0...songShit.length)
			{
				var song = songShit[i];
				var item:CircularSpriteText = new CircularSpriteText(30, 30 + (i * 55), 450, 50, FlxColor.BLUE, song.song);
				item.ID = i;
				item.targetY = i;
				item.menuItem = true;
				songStore.set(song.song, new PocketBaseObject(song.id, song.song, song.chart, song.inst, song.voices));
				groupItems.add(item);
			}
		});
		req.onError.add((_) ->
		{
			var item:CircularSpriteText = new CircularSpriteText(30, 30 + 55, 350, 50, FlxColor.RED, "Error fetching");
			groupItems.add(item);
			return;
		});
	}

	override function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (!canPress)
			return;

		switch (action)
		{
			case "ui_up":
				curOption = -1;
			case "ui_down":
				curOption = 1;
			case "confirm":
				{
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
		var chartReq:Request = Request.getFile("funkin", pbObject.id, pbObject.chart, false);
		chartReq.onSuccess.add((chart:String) ->
		{
			ChartLoader.netChart = chart;
			room.send('report_status', 'Loading inst');

			var instReq:Request = Request.getFile("funkin", pbObject.id, pbObject.inst, true);
			instReq.onSuccess.add((inst:Sound) ->
			{
				ChartLoader.netInst = inst;
				room.send('report_status', 'Checking voices');

				if (pbObject.voices != "")
				{
					room.send('report_status', 'Loading voices');
					var voicReq:Request = Request.getFile("funkin", pbObject.id, pbObject.voices, true);
					voicReq.onSuccess.add((voices:Sound) ->
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
}
