package funkin.states;

import backend.Save;
import backend.input.Controls;
import base.MusicBeatState;
import base.TransitionState;
import base.sprites.*;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.substates.vfs.*;
import lime.math.Vector2;

using StringTools;

// So the substates require pressing confirm twice to actually work, its something weird and im looking into it
class VFSManagement extends MusicBeatState
{
	private var grpOptions:FlxTypedGroup<SongEntry>;
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

			item.bg.alpha = 0.35;
			item.text.alpha = 0.65;
			item.targetX = 1.5;

			if (item.targetY == 0)
			{
				item.bg.alpha = 0.55;
				item.text.alpha = 0.85;
				item.targetX = 0;
			}
		}

		return curSelected;
	}

	private var canPress:Bool = true;
	private var holdTime:Float = 0;

	private var bg:StateBG;
	private var curState:String = "listing";

	public static var songName:String = "";

	override function create()
	{
		bg = new StateBG('menuBG');
		add(bg);

		grpOptions = new FlxTypedGroup<SongEntry>();
		add(grpOptions);

		super.create();

		freshenEntries();
		addTouchControls(DPAD, UP_DOWN, A_B);
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_DOWN.state == PRESSED || controls.UI_UP.state == PRESSED)
		{
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
			{
				curSelected = (checkNewHold - checkLastHold) * (controls.UI_UP.state == PRESSED ? -1 : 1);
			}
		}

		super.update(elapsed);
	}

	override function onActionPressed(action:ActionType)
	{
		if (!canPress)
			return;

		switch (action)
		{
			default:
				return;

			case UI_UP:
				curSelected = -1;

			case UI_DOWN:
				curSelected = 1;

			case CONFIRM:
				canPress = false;

				if (curState == "listing")
				{
					switch (grpOptions.members[curSelected].text.text)
					{
						case "Add new song":
							curState = "idle";
							openSubState(new SongUpload());

						case "Add new character":
							curState = "idle";
							openSubState(new CharacterUpload());

						default:
							ChartLoader.overridenLoad = true;
							songName = grpOptions.members[curSelected].text.text;
							TransitionState.switchState(new AsyncPlayState());
					}
				}

			case BACK:
				if (curState == "idle")
				{
					freshenEntries();
					return;
				}

				canPress = false;
				TransitionState.switchState(new SongSelection());
		}
	}

	override function onActionReleased(action:ActionType)
	{
		if (FlxG.state.subState != null)
			return;

		canPress = true;
		holdTime = 0;
	}

	function regenMenu(array:Array<String>)
	{
		for (i in 0...grpOptions.members.length)
		{
			grpOptions.remove(grpOptions.members[0], true);
		}

		for (i in 0...array.length)
		{
			var entry:SongEntry = new SongEntry(0, 220, 700, array[i], 28);
			entry.initialPositions.x = (FlxG.width - entry.width) / 2;
			entry.targetY = i;
			entry.text.autoSize = false;
			entry.text.color = FlxColor.WHITE;
			entry.text.font = Paths.font("funkin.otf");
			entry.text.alignment = CENTER;
			grpOptions.add(entry);
		}
		curSelected = grpOptions.length + 1;
	}

	function freshenEntries()
	{
		Save.database.shouldPreprocess = false;
		Save.database.entries(VFS).then((songs) ->
		{
			var regen:Array<String> = [];
			for (sName in songs.keys())
			{
				if (sName == "length")
					continue;

				if (!sName.contains("character:"))
					regen.push(sName);
			}
			regen.push("Add new song");
			regen.push("Add new character");
			regenMenu(regen);
			curState = "listing";
		});
	}
}

// just a copy of BindEntry from RebindingState

@:publicFields
class SongEntry extends FlxSpriteGroup
{
	var bg:PillSprite;
	var text:FlxText;

	var targetX:Float = 0;
	var targetY:Float = 0;
	var initialPositions:Vector2 = new Vector2(0, 0);

	override public function new(X:Float, Y:Float, FieldWidth:Float, Text:String, Size:Int)
	{
		super(X, Y);

		initialPositions.setTo(X, Y);

		text = new FlxText(0, 0, FieldWidth, Text, Size, true);
		bg = new PillSprite(0, 0, Math.floor(text.width + 25), Math.floor(text.height + 25), FlxColor.BLACK);

		text.setPosition((bg.width - text.width) / 2, (bg.height - text.height) / 2);

		add(bg);
		add(text);
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = FlxMath.bound(elapsed * 9.6, 0, 1);
		x = FlxMath.lerp(x, (targetX * text.size / 2) + initialPositions.x, lerpVal);
		y = FlxMath.lerp(y, (targetY * 1.3 * height) + initialPositions.y, lerpVal);

		super.update(elapsed);
	}
}
