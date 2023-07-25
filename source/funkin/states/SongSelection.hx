package funkin.states;

import backend.Cache;
import backend.IO;
import base.TransitionState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import funkin.text.Alphabet;
import haxe.io.Bytes;
import network.MultiCallback;
import network.Request;
import network.pocketbase.Collection;
import network.pocketbase.PBRequest;
import network.pocketbase.Record.FunkinRecord;
import openfl.media.Sound;

using StringTools;

class SongSelection extends TransitionState
{
	private final pages:Array<String> = ["libraries", "funkin"];
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

	private var libIndicator:FlxText;

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
					Paths.changeLibrary(FOF, () ->
					{
						diffStore.clear();

						var regenArray:Array<String> = [];

						var assets:Array<String> = Paths.getLibraryFiles("TEXT");
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

			case "funkin":
				{
					songStore.clear();

					PBRequest.getRecords(pages[curPage]).add((funkShit:Collection<FunkinRecord>) ->
					{
						var regenArray:Array<String> = [];

						for (song in funkShit.items)
						{
							songStore.set(song.song, song);
							regenArray.push(song.song);
						}
						regenMenu(regenArray);
					});
				}
		}

		return curPage;
	}

	@:noCompletion
	private function get_curText():String
		return (grpOptions.members[curSelected] != null ? grpOptions.members[curSelected].text : "");

	var cockygf:FlxSprite;

	override function create()
	{
		new Request<Sound>({
			url: "https://storage.sancopublic.com/nexus_bf.ogg",
			type: SOUND
		}).add(function(cock)
		{
				FlxG.sound.music = new FlxSound();
				FlxG.sound.music.loadEmbedded(cock, true);
				FlxG.sound.music.play();
		});

		var bg:FlxSprite = new FlxSprite();
		bg.loadGraphic(Paths.image('menuBG'));
		bg.screenCenter();
		bg.setGraphicSize(FlxG.width, FlxG.height);
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		@:privateAccess
		libIndicator = new FlxText(0, 15, 0, 'Library loaded: ${Paths._library}', 24);
		libIndicator.setFormat(Paths.font('vcr.ttf'), 24);
		libIndicator.screenCenter(X);
		add(libIndicator);

		curPage = 0;

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
			case "ui_left":
				curPage = -1;
			case "ui_right":
				curPage = 1;

			case "confirm":
				blockInputs = true;

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

							// pending
							/*
								var curRec:FunkinRecord = songStore.get(curText);

								var chartCb:() -> Void = networkCb.add("chart:" + curRec.id);
								var instCb:() -> Void = networkCb.add("inst:" + curRec.id);
								var voicesCb:() -> Void = networkCb.add("voices:" + curRec.id);

								#if FS_ACCESS
								PBRequest.getFile(curRec, "chart", BYTES).add((chart:Bytes) ->
								{
									IO.saveSong(curRec.song, CHART, chart, 1);
									songSelected.songName = curRec.song;
									chartCb();

									PBRequest.getFile(curRec, "inst", (inst:Bytes) ->
									{
										IO.saveSong(curRec.song, INST, inst);
										instCb();

										if (curRec.voices != '')
										{
											PBRequest.getFile(curRec, "voices", (voices:Bytes) ->
											{
												IO.saveSong(curRec.song, VOICES, voices);
												voicesCb();
											}, BYTES);
										}
										else
											voicesCb();
									}, BYTES);
								});
								#else
								songSelected.isFS = false;
								PBRequest.getFile(curRec, "chart", (chart:String) ->
								{
									songSelected.netChart = chart;
									chartCb();

									PBRequest.getFile(curRec, "inst", (inst:Sound) ->
									{
										songSelected.netInst = inst;
										instCb();

										if (curRec.voices != '')
										{
											PBRequest.getFile(curRec, "voices", (voices:Sound) ->
											{
												songSelected.netVoices = voices;
												voicesCb();
											}, SOUND);
										}
										else
											voicesCb();
									}, SOUND);
								}, RAW_STRING);
								#end */
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
