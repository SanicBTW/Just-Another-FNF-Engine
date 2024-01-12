package funkin.states.options;

import backend.input.Controls.ActionType;
import backend.input.Controls;
import backend.scripting.*;
import base.MusicBeatState;
import base.sprites.*;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.shapes.*;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Timer;
import lime.math.Vector2;

enum SelectionState
{
	SELECTING;
	LISTING;
	WAITING;
}

class RebindingState extends MusicBeatState
{
	var bg:StateBG;

	var entryGroup:FlxTypedGroup<BindEntry>;
	var bindingGroup:Null<BindingList>;

	var holdTime:Float = 0;
	var canPress:Bool = true;

	var prevSelected:Int = 0; // only used when switching states
	var curSelected(default, set):Int;

	@:noCompletion
	private function set_curSelected(val:Int):Int
	{
		switch (curState)
		{
			case SELECTING:
				curSelected += val;

				var curEntry:BindEntry = (entryGroup.members[curSelected] != null) ? entryGroup.members[curSelected] : entryGroup.members[0];
				var prevEntry:BindEntry = (entryGroup.members[curSelected - val] != null) ? entryGroup.members[curSelected - val] : entryGroup.members[0];

				if (curEntry.text.text.indexOf("Actions") > -1 || prevEntry.text.text.indexOf("Actions") > -1)
					curSelected += val;

				if (curSelected < 0)
					curSelected = entryGroup.length - 1;
				if (curSelected >= entryGroup.length)
					curSelected = 1; // forced

				var the:Int = 0;

				for (entry in entryGroup)
				{
					entry.targetY = the - curSelected;
					the++;

					repositionEntry(entry);

					if (entry.targetY == 0)
					{
						entry.bg.alpha = 0.55;
						entry.text.alpha = 0.85;
						entry.targetX = 0;
					}
				}

			case LISTING:

			case WAITING:
		}
		return curSelected;
	}

	var curState(default, set):SelectionState = SELECTING;

	@:noCompletion
	private function set_curState(newState:SelectionState):SelectionState
	{
		if (curState == newState)
			return curState;

		switch (newState)
		{
			// make a loop since curSelected = 0 does nothing and it should force the loop to run and reposition everything but since it doesnt just make it when going back
			case SELECTING:
				if (bindingGroup != null)
				{
					bindingGroup.targetX = 50;
					// just in case that shit didnt end the animation lol
					Timer.delay(() ->
					{
						bindingGroup.destroy();
						remove(bindingGroup);
						bindingGroup = null;
					}, 1000);
				}

				var the:Int = 0;

				for (entry in entryGroup)
				{
					entry.targetY = the - prevSelected;
					the++;

					repositionEntry(entry);

					if (entry.targetY == 0)
					{
						entry.bg.alpha = 0.55;
						entry.text.alpha = 0.85;
						entry.targetX = 0;
					}
				}

			case LISTING:
				var enWidth:Float = 0;
				for (entry in entryGroup)
				{
					entry.targetX = -20;
					enWidth = entry.width;
				}

				prevSelected = curSelected;

				if (bindingGroup == null)
				{
					bindingGroup = new BindingList(enWidth + 75, 250);
					add(bindingGroup);
				}

			case WAITING:
				trace("Niggers");
		}

		return curState = newState;
	}

	override public function create()
	{
		bg = new StateBG('menuBG');
		add(bg);

		entryGroup = new FlxTypedGroup<BindEntry>();
		add(entryGroup);

		var i = 0;
		for (data in [
			"System Actions", "CONFIRM", "BACK", "PAUSE", "UI Actions", "UI_LEFT", "UI_DOWN", "UI_UP", "UI_RIGHT", "Note Actions", "NOTE_LEFT", "NOTE_DOWN",
			"NOTE_UP", "NOTE_RIGHT"
		])
		{
			var entry:BindEntry = new BindEntry(0, 320, 600, data, 32);
			entry.initialPositions.x = (FlxG.width - entry.width) / 2;
			entry.targetY = i;
			entry.text.autoSize = false;
			entry.text.color = FlxColor.WHITE;
			entry.text.font = Paths.font("open_sans.ttf");

			if (data.indexOf("Actions") > -1)
				entry.text.alignment = CENTER;
			else
				entry.text.alignment = LEFT;

			entryGroup.add(entry);
			i++;
		}
		curSelected = entryGroup.length + 1;

		super.create();
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
				curState = switch (curState)
				{
					case SELECTING: LISTING;
					case LISTING: WAITING;
					case WAITING: WAITING; // confirm on listing is reserved to waiting but pressing confirm on waiting does nothing
				}
				canPress = false;

			case BACK:
				curState = switch (curState)
				{
					case SELECTING: SELECTING; // cannot go back on selecting
					case LISTING: SELECTING;
					case WAITING: LISTING;
				}
				canPress = false;
		}
	}

	override function onActionReleased(action:ActionType)
	{
		canPress = true;
		holdTime = 0;
	}

	function repositionEntry(entry:BindEntry)
	{
		if (entry.text.alignment != CENTER)
		{
			entry.bg.alpha = 0.35;
			entry.text.alpha = 0.65;
			entry.targetX = 1.5;
		}
		else if (entry.text.alignment == CENTER)
		{
			entry.bg.alpha = 0.65;
			entry.text.alpha = 0.95;
			entry.targetX = 0;
		}
	}
}

@:publicFields
class BindEntry extends FlxSpriteGroup
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

		text = new FlxText(12.5, 12.5, FieldWidth, Text, Size, true);
		bg = new PillSprite(0, 0, Math.floor(text.width + 25), Math.floor(text.height + 25), FlxColor.BLACK);

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

@:publicFields
class BindingList extends FlxSpriteGroup
{
	var bg:RoundSprite;
	var keys:FlxTypedGroup<FlxSprite>;
	var buttons:FlxTypedGroup<ControllerButton>;

	var targetX:Float = 0;
	var targetY:Float = 0;
	var initialPositions:Vector2 = new Vector2(0, 0);

	override public function new(X:Float = 0, Y:Float = 0)
	{
		super(X, Y);

		initialPositions.setTo(X, Y);

		bg = new RoundSprite(0, 0, 400, 400, [50], FlxColor.BLACK);
		bg.alpha = 0.75;

		add(bg);
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = FlxMath.bound(elapsed * 9.6, 0, 1);
		x = FlxMath.lerp(x, (targetX * width / 2) + initialPositions.x, lerpVal);
		y = FlxMath.lerp(y, (targetY * 1.3 * height) + initialPositions.y, lerpVal);

		super.update(elapsed);
	}
}
