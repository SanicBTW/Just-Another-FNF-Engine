package states;

import base.MusicBeatState;
import base.ScriptableState;
import base.pocketbase.Collections.Funkin as FunkCollection;
import base.pocketbase.Collections.Funkin_Old;
import base.pocketbase.Collections.PocketBaseObject;
import base.pocketbase.Request;
import base.system.Conductor;
import base.system.Controls;
import base.system.DatabaseManager;
import base.ui.CircularSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import funkin.Character;
import haxe.Json;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;
import shader.CoolShader;
import shader.Noise.NoiseShader;
import shader.PixelEffect;
import states.config.EarlyConfig;
import states.config.KeybindsState;
import substates.LoadingState;

using StringTools;

// I need to rewrite this shit :skull:
class RewriteMenu extends MusicBeatState
{
	// Options available
	var options:Array<String> = ["Assets", "Online", "Settings", "Shaders"];
	var subOptions:Map<String, Array<Dynamic>> = [
		// bruh
		"Assets" => ["Select song"],
		"Online" => ["Select song", "Choose collection", "Socket test"],
		"Settings" => ["Options", "Keybinds"],
		"Shaders" => ["Drug", "Pixel", "Noise", "Disable"],
		"Character selection" => ["soon"]
	];
	var groupItems:FlxTypedGroup<CircularSpriteText>;

	// Menu essentials
	var canPress:Bool = true;
	var curState(default, set):SelectionState = SELECTING;
	var curOption(default, set):Int = 0;
	var curOptionStr:String;
	var catStr:String;
	var subStr:String;

	// da bf
	var boyfriend:Character;

	// Shaders
	var shaderFilter:ShaderFilter;
	var pixelShader:PixelEffect;
	var noiseShader:NoiseShader;

	// Online
	var collections:Array<String> = ["New", "Old"];
	var selectedCollection:String = "New";
	var songStore:Map<String, PocketBaseObject> = new Map();

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

		boyfriend = new Character(690, -100, true, 'bf');
		boyfriend.scale.set(0.9, 0.9);
		add(boyfriend);

		super.create();

		applyShader(DatabaseManager.get("shader") != null ? DatabaseManager.get("shader") : "Disable");

		Conductor.boundSong = bgMusic;
		Conductor.boundState = this;
		Conductor.changeBPM(128);

		bgMusic.audioSource = Paths.music("mainRewrite");
		bgMusic.loopAudio = true;
		bgMusic.play();
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

	override public function beatHit()
	{
		super.beatHit();

		if (curBeat % 2 == 0)
		{
			boyfriend.dance();
		}
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
								var reqURL:String = Request.getRecords((isOld ? "old_fnf_charts" : "funkin"));
								Request.onSuccess.addOnce((det:Array<Dynamic>) ->
								{
									if (det[0] != reqURL)
									{
										trace("A request that didn't match the URL was catched");
										return;
									}
								});
								/*
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
								});*/
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
								bgMusic.stop();
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
								bgMusic.stop();
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

			case "Settings":
				{
					switch (curOptionStr)
					{
						case "Options":
							ScriptableState.switchState(new EarlyConfig());
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
				pixelShader.PIXEL_FACTOR = 512.;
				shaderFilter = new ShaderFilter(pixelShader.shader);
			case "Noise":
				noiseShader = new NoiseShader();
				shaderFilter = new ShaderFilter(noiseShader);
			case "Disable":
				FlxG.camera.setFilters([]);
		}

		DatabaseManager.set("shader", shader);

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
