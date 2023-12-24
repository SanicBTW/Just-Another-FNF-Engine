package funkin.states;

import backend.IO;
import backend.input.Controls.ActionType;
import base.MusicBeatState;
import base.TransitionState;
import base.sprites.*;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.math.Vector2;

using StringTools;

// FileSystem selection
class FSSelection extends MusicBeatState
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

	// lazy to put diffs, mb, the diff option will be added as a color representing the difficulty of the song "easy green" "normal yellow" "hard red" on the entry bg
	override function create()
	{
		bg = new StateBG('menuBG');
		add(bg);

		grpOptions = new FlxTypedGroup<SongEntry>();
		add(grpOptions);

		var songs:Array<String> = IO.getFolderFiles(SONGS);

		var i:Int = 0;
		for (song in songs)
		{
			var entry:SongEntry = new SongEntry(0, 220, 700, song.replace("-", " "), 28);
			entry.initialPositions.x = (FlxG.width - entry.width) / 2;
			entry.targetY = i;
			entry.text.autoSize = false;
			entry.text.color = FlxColor.WHITE;
			entry.text.font = Paths.font("funkin.otf");
			entry.text.alignment = CENTER;
			grpOptions.add(entry);
			i++;
		}
		curSelected = grpOptions.length + 1;

		super.create();

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
				SongSelection.songSelected.songName = grpOptions.members[curSelected].text.text.replace(" ", "-");
				SongSelection.songSelected.isFS = true;
				TransitionState.switchState(new PlayState());

			case BACK:
				canPress = false;
				TransitionState.switchState(new SongSelection());
		}
	}

	override function onActionReleased(action:ActionType)
	{
		canPress = true;
		holdTime = 0;
	}
}

// just a copy of BnidEntry from RebindingState

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
