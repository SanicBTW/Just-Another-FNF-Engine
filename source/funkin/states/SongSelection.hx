package funkin.states;

import backend.DiscordPresence;
import backend.IO;
import backend.input.Controls.ActionType;
import base.TransitionState;
import base.sprites.StateBG;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.text.Alphabet;
import haxe.io.Bytes;
import network.MultiCallback;
import network.pocketbase.Collection;
import network.pocketbase.PBRequest;
import network.pocketbase.Record.FunkinRecord;
import openfl.media.Sound;

using StringTools;

class SongSelection extends TransitionState
{
	private final pages:Array<String> = ["libraries", "funkin", "quaver", "vfs"];
	private var curPage(default, set):Int = 0;
	private var curSelected(default, set):Int = 0;
	private var curText(get, null):String;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var diffStore:Map<String, Int> = [];
	private var songStore:Map<String, FunkinRecord> = [];

	private var blockInputs = false;

	public static var songSelected:SongAsset = {
		songName: null,
		songDiff: 1,
		netChart: null,
		netInst: null,
		netVoices: null,
		isFS: false
	};

	private var networkCb:MultiCallback = new MultiCallback(() ->
	{
		TransitionState.switchState(new PlayState());
	});

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

	@:noCompletion
	private function set_curPage(value:Int):Int
	{
		curPage += value;

		if (curPage < 0)
			curPage = pages.length - 1;
		if (curPage >= pages.length)
			curPage = 0;

		switch (pages[curPage])
		{
			case "libraries":
				{
					try
					{
						Paths.changeLibrary(FOF, (lib) ->
						{
							diffStore.clear();

							var regenArray:Array<String> = [];

							var assets:Array<String> = lib.list("TEXT");
							for (i in 0...assets.length)
							{
								if (assets[i].contains("songs"))
								{
									// Smart shit right here lol
									var fullName:String = assets[i].substring(assets[i].lastIndexOf("/") + 1);
									var song:String = fullName.substring(0, fullName.lastIndexOf("-"));
									var diff:String = fullName.substring(fullName.lastIndexOf("-"), fullName.lastIndexOf("."));

									diffStore.set(song, ChartLoader.intDiffMap.get(diff));
									regenArray.insert(i, song);
								}
							}
							regenMenu(regenArray);
						});
					}
					catch (ex)
					{
						trace(ex);
						diffStore.set("fight-or-flight", 2);
						regenMenu(["fight-or-flight"]);
					}
				}

			case "funkin":
				{
					songStore.clear();

					PBRequest.getRecords(pages[curPage]).then((funkShit:Collection<FunkinRecord>) ->
					{
						var regenArray:Array<String> = [];

						for (song in funkShit.items)
						{
							songStore.set(song.song, song);
							regenArray.push(song.song);
						}
						regenMenu(regenArray);
					}).catchError((ex) ->
						{
							regenMenu(["Failed to request"]);
						});
				}

			case "quaver":
				{
					TransitionState.switchState(new quaver.states.QuaverSelection());
				}

			case "vfs":
				{
					TransitionState.switchState(new VFSManagement());
				}
		}

		return curPage;
	}

	@:noCompletion
	private function get_curText():String
		return (grpOptions.members[curSelected] != null ? grpOptions.members[curSelected].text : "");

	override function create()
	{
		var bg:StateBG = new StateBG('M_menuBG');
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		// idk since when libIndicator has been here but damn it stayed for a long ass time

		curPage = 0;

		// It was time to fix it lol
		DiscordPresence.changePresence("Scrolling through the menus");

		super.create();

		addTouchControls(DPAD, LEFT_FULL, A_B);
	}

	override function onActionPressed(action:ActionType)
	{
		if (blockInputs)
			return;

		switch (action)
		{
			default:
				return;

			case UI_UP:
				curSelected = -1;
			case UI_DOWN:
				curSelected = 1;
			case UI_LEFT:
				curPage = -1;
			case UI_RIGHT:
				curPage = 1;

			case CONFIRM:
				blockInputs = true;
				ChartLoader.overridenLoad = false;

				switch (pages[curPage])
				{
					case "libraries":
						{
							songSelected = {
								songName: curText,
								songDiff: diffStore.get(curText),
								netChart: null,
								netInst: null,
								netVoices: null,
								isFS: false
							};
							TransitionState.switchState(new PlayState());
						}

					case "funkin":
						{
							#if FS_ACCESS
							songSelected.isFS = true;

							if (IO.existsOnFolder(SONGS, curText))
							{
								songSelected.songName = curText;
								networkCb.callback();
								return;
							}
							#end

							var curRec:FunkinRecord = songStore.get(curText);

							var chartCb:() -> Void = networkCb.add("chart:" + curRec.id);
							var instCb:() -> Void = networkCb.add("inst:" + curRec.id);
							var voicesCb:() -> Void = networkCb.add("voices:" + curRec.id);

							#if FS_ACCESS
							PBRequest.getFile(curRec, 'chart', STRING).then((chart:String) ->
							{
								IO.saveSong(curRec.song, CHART, chart, 1);
								songSelected.songName = curRec.song;
								chartCb();

								PBRequest.getFile(curRec, "inst", BYTES).then((inst:Bytes) ->
								{
									IO.saveSong(curRec.song, INST, inst);
									instCb();

									if (curRec.voices != '')
									{
										PBRequest.getFile(curRec, "voices", BYTES).then((voices:Bytes) ->
										{
											IO.saveSong(curRec.song, VOICES, voices);
											voicesCb();
										});
									}
									else
										voicesCb();
								});
							});
							#else
							songSelected.isFS = false;
							PBRequest.getFile(curRec, 'chart', STRING).then((chart:String) ->
							{
								songSelected.netChart = chart;
								chartCb();

								PBRequest.getFile(curRec, "inst", SOUND).then((inst:Sound) ->
								{
									songSelected.netInst = inst;
									instCb();

									if (curRec.voices != '')
									{
										PBRequest.getFile(curRec, "voices", SOUND).then((voices:Sound) ->
										{
											songSelected.netVoices = voices;
											voicesCb();
										});
									}
									else
										voicesCb();
								});
							});
							#end
						}
				}
		}
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

typedef SongAsset =
{
	var songName:String;
	var songDiff:Int;
	var netChart:String;
	var netInst:Sound;
	var netVoices:Null<Sound>;
	var isFS:Bool;
}
