package states;

import base.MusicBeatState;
import base.ScriptableState;
import base.pocketbase.Collections.Funkin as FunkCollection;
import base.pocketbase.Collections.Funkin_Old;
import base.pocketbase.Collections.PocketBaseObject;
import base.pocketbase.Request;
import base.system.Controls;
import base.system.DatabaseManager;
import base.ui.Alphabet;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.ChartLoader;
import haxe.Json;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets;
import shader.*;
import shader.Noise.NoiseShader;
import states.config.EarlyConfig;
import states.config.KeybindsState;
import states.online.ConnectingState;
import substates.LoadingState;
import substates.online.CodeState;

using StringTools;

class AlphabetMenu extends MusicBeatState
{
	private final pages:Array<String> = ["assets", "funkin", "old_fnf_charts", "vs", "settings", "shaders"];

	private var curPage(default, set):Int = 0;

	private var groupItems:FlxTypedGroup<Alphabet>;

	private var songStore:Map<String, PocketBaseObject> = [];

	private var curSelected(default, set):Int = 0;

	private var curText(get, null):String;

	// Shaders
	private var shaderFilter:ShaderFilter;
	private var pixelShader:PixelEffect;
	private var noiseShader:NoiseShader;

	private var blockInputs = false;

	@:noCompletion
	private function set_curSelected(value:Int):Int
	{
		curSelected += value;

		if (curSelected < 0)
			curSelected = groupItems.members.length - 1;
		if (curSelected >= groupItems.members.length)
			curSelected = 0;

		var tf:Int = 0;

		for (item in groupItems.members)
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
			case "assets":
				{
					var songAssets:Array<String> = Assets.getLibrary("songs").list("TEXT");
					for (i in 0...songAssets.length)
					{
						songAssets[i] = songAssets[i].replace("assets/songs/", "");
						songAssets[i] = songAssets[i].substring(songAssets[i].lastIndexOf("/") + 1, songAssets[i].indexOf("-hard"));
					}
					regenMenu(songAssets);
				}

			case "funkin" | "old_fnf_charts":
				{
					songStore.clear();

					var isOld:Bool = (pages[curPage] == "old_fnf_charts");
					Request.getRecords(pages[curPage], (data:String) ->
					{
						if (data == "Failed to fetch")
						{
							regenMenu(["Failed to fetch"]);
							return;
						}

						var regenArray:Array<String> = [];
						var songShit:Array<FunkCollection & Funkin_Old> = cast Json.parse(data).items;
						for (song in songShit)
						{
							songStore.set((isOld ? song.song_name : song.song),
								new PocketBaseObject(song.id, (isOld ? song.song_name : song.song), (isOld ? song.chart_file : song.chart), song.inst,
									song.voices));
							regenArray.push((isOld ? song.song_name : song.song));
						}
						regenMenu(regenArray);
					});
				}

			case "vs":
				{
					regenMenu(["host", #if html5 "join by id" #end]);
				}

			case "settings":
				{
					regenMenu(["settings", "keybinds"]);
				}

			case "shaders":
				{
					regenMenu(["Drug", "Pixel", "Noise", "Disable"]);
				}
		}

		return curPage;
	}

	private function get_curText():String
		return (groupItems.members[curSelected] != null ? groupItems.members[curSelected].text : "");

	override public function create()
	{
		Controls.setActions(UI);

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuSDefault2"));
		bg.screenCenter();
		bg.antialiasing = SaveData.antialiasing;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		add(bg);

		groupItems = new FlxTypedGroup<Alphabet>();
		add(groupItems);

		curPage = 0;

		applyShader(DatabaseManager.get("shader") != null ? DatabaseManager.get("shader") : "Disable");

		FlxG.sound.playMusic(Paths.music("freakyMenu"));

		super.create();
	}

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
								ChartLoader.netChart = null;
								ChartLoader.netInst = null;
								ChartLoader.netVoices = null;
								ScriptableState.switchState(new PlayTest(curText));
							}
						case "funkin" | "old_fnf_charts":
							{
								if (curText == "Failed to fetch")
									return;

								var pbObject:PocketBaseObject = songStore.get(curText);
								persistentUpdate = false;
								blockInputs = true;
								openSubState(new LoadingState(pages[curPage], pbObject));
							}
						case "vs":
							{
								if (curText == "join by id")
								{
									openSubState(new CodeState());
									return;
								}
								else
									ScriptableState.switchState(new ConnectingState('host'));
							}
						case "settings":
							{
								ScriptableState.switchState((curText == "settings") ? new EarlyConfig() : new KeybindsState());
							}
						case "shaders":
							{
								applyShader(curText);
							}
					}
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
		curSelected = groupItems.length + 1;
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
		DatabaseManager.save();

		if (shaderFilter != null)
			FlxG.camera.setFilters([shaderFilter]);
	}
}
