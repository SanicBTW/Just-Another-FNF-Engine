package states;

import base.MusicBeatState;
import base.ScriptableState;
import base.pocketbase.Collections.Funkin as FunkCollection;
import base.pocketbase.Collections.Funkin_Old;
import base.pocketbase.Collections.PocketBaseObject;
import base.pocketbase.Request;
import base.system.Conductor;
import base.system.Controls;
import base.system.SaveFile;
import base.ui.CircularSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import funkin.Character;
import funkin.ChartLoader;
import haxe.Json;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;
import shader.CoolShader;
import shader.Noise.NoiseShader;
import shader.PixelEffect;
import states.config.KeybindsState;
import states.config.Option;
import substates.LoadingState;

using StringTools;

class RewriteMenu extends MusicBeatState
{
	// Options available
	private var options:Array<String> = ["Assets", "Online", "1v1", "Settings", "Shaders"];
	private var subOptions:Map<String, Array<Dynamic>> = [
		// bruh
		"Assets" => ["Select song"],
		"Online" => ["Select song", "Choose collection", "VS"],
		"1v1" => ["Host", "Connect"],
		"Settings" => ["Options", "Keybinds"],
		"Shaders" => ["Drug", "Pixel", "Noise", "Disable"],
	];
	private var groupItems:FlxTypedGroup<CircularSpriteText>;

	// Menu essentials
	private var canPress:Bool = true;
	private var curState(default, set):SelectionState = SELECTING;
	private var curOption(default, set):Int = 0;
	private var curOptionStr:String;
	private var catStr:String;
	private var subStr:String;

	// Shaders
	private var shaderFilter:ShaderFilter;
	private var pixelShader:PixelEffect;
	private var noiseShader:NoiseShader;

	// Online songs
	private var collections:Array<String> = ["New", "Old"];
	private var selectedCollection:String = "New";
	private var songStore:Map<String, PocketBaseObject> = new Map();

	@:noCompletion
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

	@:noCompletion
	private function set_curState(newState:SelectionState):SelectionState
	{
		canPress = false;
		if (groupItems.members.length > 0)
		{
			for (i in 0...groupItems.members.length)
			{
				groupItems.remove(groupItems.members[0], true);
			}
		}

		switch (newState)
		{
			case SELECTING:
				{
					catStr = null;
					for (i in 0...options.length)
					{
						var item:CircularSpriteText = new CircularSpriteText(30, 30 + (i * 55), 350, 50, FlxColor.GRAY, options[i]);
						item.ID = i;
						groupItems.add(item);
					}
				}
			case SUB_SELECTION:
				{
					if (curState != LISTING)
						catStr = curOptionStr;
					for (i in 0...subOptions.get(catStr).length)
					{
						var item:CircularSpriteText = new CircularSpriteText(30, 30 + (i * 55), 350, 50, FlxColor.GRAY, subOptions.get(catStr)[i]);
						item.ID = i;
						groupItems.add(item);
					}
				}
			case LISTING:
				{
					subStr = curOptionStr;
					regenListing();
				}
		}

		curOption = groupItems.length + 1;

		return curState = newState;
	}

	override public function create()
	{
		Controls.setActions(UI);

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuSDefault2"));
		bg.screenCenter();
		bg.antialiasing = SaveData.antialiasing;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		add(bg);

		groupItems = new FlxTypedGroup<CircularSpriteText>();
		add(groupItems);

		curState = SELECTING;
		canPress = true;

		var opt = new Option(0, 0, "sexo", "negros", "pauseMusic", UNKNOWN, "tea-time", ["tea-time", "breakfast"], FlxG.width - 30);
		opt.screenCenter();
		add(opt);

		super.create();

		applyShader(SaveFile.get("shader") != null ? SaveFile.get("shader") : "Disable");

		Conductor.changeBPM(102);
		FlxG.sound.playMusic(Paths.music("freakyMenu"));
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (!canPress)
			return;

		switch (curState)
		{
			case SELECTING:
				{
					switch (action)
					{
						case "confirm":
							{
								curState = SUB_SELECTION;
							}

						case "ui_up":
							curOption = -1;
						case "ui_down":
							curOption = 1;
					}
				}

			case SUB_SELECTION:
				{
					switch (action)
					{
						case "confirm":
							{
								checkSub();
							}

						case "back":
							{
								curState = SELECTING;
							}

						case "ui_up":
							curOption = -1;
						case "ui_down":
							curOption = 1;
					}
				}

			case LISTING:
				{
					switch (action)
					{
						case "confirm":
							{
								handleListing();
							}

						case "back":
							{
								curState = SUB_SELECTION;
							}

						case "ui_up":
							curOption = -1;
						case "ui_down":
							curOption = 1;
					}
				}
		}
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);

		canPress = true;
	}

	override public function update(elapsed:Float)
	{
		if (noiseShader != null)
			noiseShader.elapsed.value = [FlxG.game.ticks / 1000];

		super.update(elapsed);
	}

	private function regenListing()
	{
		switch (catStr)
		{
			case "Assets":
				{
					switch (subStr)
					{
						case "Select song":
							{
								var songAssets:Array<String> = Assets.getLibrary("songs").list("TEXT");
								for (i in 0...songAssets.length)
								{
									songAssets[i] = songAssets[i].replace("assets/songs/", "");
									songAssets[i] = songAssets[i].substring(songAssets[i].lastIndexOf("/") + 1, songAssets[i].indexOf("-hard"));

									var song:String = songAssets[i];
									var item:CircularSpriteText = new CircularSpriteText(30, 30 + (i * 55), 450, 50, FlxColor.GRAY, song);
									item.targetY = i;
									item.ID = i;
									item.menuItem = true;
									groupItems.add(item);
								}
							}
					}
				}
			case "Online":
				{
					switch (subStr)
					{
						case "Select song":
							{
								songStore.clear();

								var isOld:Bool = (selectedCollection == "Old");
								Request.getRecords((isOld ? "old_fnf_charts" : "funkin"), (data:String) ->
								{
									if (data == "Failed to fetch")
									{
										var item:CircularSpriteText = new CircularSpriteText(30, 30 + 55, 350, 50, FlxColor.RED, "Error fetching");
										groupItems.add(item);
										return;
									}

									var songShit:Array<FunkCollection & Funkin_Old> = cast Json.parse(data).items;
									for (i in 0...songShit.length)
									{
										var song = songShit[i];
										var item:CircularSpriteText = new CircularSpriteText(30, 30 + (i * 55), 450, 50, FlxColor.GRAY,
											(isOld ? song.song_name : song.song));
										item.ID = i;
										item.targetY = i;
										item.menuItem = true;
										songStore.set((isOld ? song.song_name : song.song),
											new PocketBaseObject(song.id, (isOld ? song.song_name : song.song), (isOld ? song.chart_file : song.chart),
												song.inst, song.voices));
										groupItems.add(item);
									}
								});
							}

						case "Choose collection":
							{
								for (i in 0...collections.length)
								{
									var item:CircularSpriteText = new CircularSpriteText(30, 30 + (i * 55), 350, 50, FlxColor.GRAY, collections[i]);
									item.ID = i;
									groupItems.add(item);
								}
							}
					}
				}
		}
	}

	private function handleListing()
	{
		switch (catStr)
		{
			case "Assets":
				{
					switch (subStr)
					{
						// Only entry lol
						case "Select song":
							{
								// Clean the chart loader left over vars from online shit
								ChartLoader.netChart = null;
								ChartLoader.netInst = null;
								ChartLoader.netVoices = null;
								ScriptableState.switchState(new PlayTest(curOptionStr));
							}
					}
				}
			case "Online":
				{
					switch (subStr)
					{
						case "Select song":
							{
								if (curOptionStr == "Error fetching")
									return;

								var pbObject:PocketBaseObject = songStore.get(curOptionStr);
								persistentUpdate = false;
								canPress = false;
								openSubState(new LoadingState(selectedCollection == "Old" ? "old_fnf_charts" : "funkin", pbObject));
							}

						case "Choose collection":
							{
								selectedCollection = curOptionStr;
								curState = SUB_SELECTION;
							}
					}
				}
		}
	}

	private function checkSub()
	{
		if (catStr == null)
			return;

		switch (catStr)
		{
			default:
				curState = LISTING;

			case "1v1":
				{
					switch (curOptionStr)
					{
						case "Host":
							{
								// base.server.UDPServer.init();
							}

						case "Connect":
							{}
					}
				}

			case "Settings":
				{
					switch (curOptionStr)
					{
						// case "Options":
						//	ScriptableState.switchState(new EarlyConfig());
						case "Keybinds":
							ScriptableState.switchState(new KeybindsState());
					}
				}

			case "Shaders":
				{
					applyShader(curOptionStr);
				}
		}
	}

	private function applyShader(shader:String)
	{
		if (shaderFilter != null)
			shaderFilter = null;

		if (pixelShader != null)
			pixelShader = null;

		if (noiseShader != null)
			noiseShader = null;

		switch (shader)
		{
			case "Drug":
				shaderFilter = new ShaderFilter(new CoolShader());
			case "Pixel":
				pixelShader = new PixelEffect();
				pixelShader.PIXEL_FACTOR = 1024.;
				shaderFilter = new ShaderFilter(pixelShader.shader);
			case "Noise":
				noiseShader = new NoiseShader();
				shaderFilter = new ShaderFilter(noiseShader);
			case "Disable":
				FlxG.camera.setFilters([]);
		}

		SaveFile.set("shader", shader);
		SaveFile.save();

		if (shaderFilter != null)
			FlxG.camera.setFilters([shaderFilter]);
	}
}

enum SelectionState
{
	SELECTING;
	SUB_SELECTION;
	LISTING;
}
