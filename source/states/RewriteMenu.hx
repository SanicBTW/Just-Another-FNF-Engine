package states;

import base.MusicBeatState;
import base.ScriptableState;
import base.system.Conductor;
import base.system.Controls;
import base.system.DatabaseManager;
import base.ui.CircularSprite;
import base.ui.RoundedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import funkin.Character;
import openfl.filters.ShaderFilter;
import shader.CoolShader;
import shader.Noise.NoiseShader;
import shader.PixelEffect;
import states.config.KeybindsState;

class RewriteMenu extends MusicBeatState
{
	var options:Array<String> = ["Online", "Settings", "Shaders", "Character selection"];
	var subOptions:Map<String, Array<Dynamic>> = [
		"Online" => ["Select song", "Choose collection"],
		"Settings" => ["Options", "Keybinds"],
		"Shaders" => ["Drug", "Pixel", "Noise", "Disable"],
		"Character selection" => ["soon"]
	];
	var groupItems:FlxTypedGroup<CircularSpriteText>;

	var canPress:Bool = true;
	var pastStr:String;
	var curStr:String;
	var curState(default, set):SelectionState = SELECTING;
	var curOption(default, set):Int = 0;

	var boyfriend:Character;

	var shaderFilter:ShaderFilter;
	var pixelShader:PixelEffect;
	var noiseShader:NoiseShader;

	private function set_curOption(value:Int):Int
	{
		curOption += value;

		if (curOption < 0)
			curOption = groupItems.members.length - 1;
		if (curOption >= groupItems.members.length)
			curOption = 0;

		for (item in groupItems)
		{
			item.selected = (item.ID == curOption);
		}

		curStr = groupItems.members[curOption].bitmapText.text;

		return curOption;
	}

	private function set_curState(newState:SelectionState):SelectionState
	{
		canPress = false;
		if (groupItems.members.length > 0)
		{
			pastStr = groupItems.members[curOption].bitmapText.text;

			for (i in 0...groupItems.members.length)
			{
				groupItems.remove(groupItems.members[0], true);
			}
		}

		switch (newState)
		{
			case SELECTING:
				{
					for (i in 0...options.length)
					{
						var item:CircularSpriteText = new CircularSpriteText(30, 30 + (i * 55), 350, 50, FlxColor.GRAY, options[i]);
						item.ID = i;
						groupItems.add(item);
					}
				}
			case SUB_SELECTION:
				{
					for (i in 0...subOptions.get(curStr).length)
					{
						var item:CircularSpriteText = new CircularSpriteText(30, 30 + (i * 55), 350, 50, FlxColor.GRAY, subOptions.get(curStr)[i]);
						item.ID = i;
						groupItems.add(item);
					}
				}
			case LISTING:
				{}
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
								trace("Pressed on listing");
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
			trace("beat hit");
			boyfriend.dance();
		}
	}

	private function checkSub()
	{
		if (pastStr == null)
			return;

		switch (pastStr)
		{
			default:
				curState = LISTING;

			case "Settings":
				{
					switch (curStr)
					{
						case "Options":
						case "Keybinds":
							ScriptableState.switchState(new KeybindsState());
					}
				}

			case "Shaders":
				{
					applyShader(curStr);
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
