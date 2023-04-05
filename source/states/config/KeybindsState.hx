package states.config;

import base.MusicBeatState;
import base.ScriptableState;
import base.system.Controls;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.Stage;
import haxe.ds.StringMap;
import states.config.ConfigObjects.KeybindSelector;

using StringTools;

class KeybindsState extends MusicBeatState
{
	var helpText:KeybindSelector;
	var stage:Stage;

	var currentActions:FlxTypedGroup<KeybindSelector>;
	var bindedActions:FlxTypedGroup<KeybindSelector>;

	var actions:Array<ActionType> = [UI, NOTES];
	var curActions(default, set):Int = 0;
	var curSelected(default, set):Int = 0;
	var curKeySelected(default, set):Int = 0;

	var instance:KeybindsState;

	var canPress:Bool = true;
	var listening:Bool = false;
	var currentState(default, set):SelectionState = SELECTING;

	// shit isnt in order m8
	var actionsOrder:Map<String, Int> = ["left" => 0, "down" => 1, "up" => 2, "right" => 3];

	private function set_currentState(newState:SelectionState):SelectionState
	{
		var currentObject:KeybindSelector = currentActions.members[curSelected];
		if (newState == SELECTING)
		{
			for (i in 0...bindedActions.length)
			{
				bindedActions.remove(bindedActions.members[0], true);
			}
			currentObject.forceX = 30;
			currentObject.yAdd = 0;

			if (helpText.alpha != 0)
				helpText.alpha = 0;
		}

		if (newState == LISTING)
		{
			currentObject.forceX = 640;
			currentObject.yAdd = -225 + (currentObject.height / 2);
			if (bindedActions.length <= 0)
				regenBinded(currentObject);

			if (helpText.alpha != 1)
				helpText.alpha = 1;
			helpText.bitText.text = "Press R to restore a bind";

			if (bindedActions.length > 0)
				bindedActions.members[curKeySelected].scale.set(1, 1);
		}

		if (newState == WAITING)
		{
			helpText.bitText.text = "Press ESC to cancel binding";
			bindedActions.members[curKeySelected].scale.set(1.1, 1.1);
		}

		return currentState = newState;
	}

	private function set_curSelected(val:Int):Int
	{
		curSelected += val;

		if (curSelected < 0)
			curSelected = currentActions.length - 1;
		if (curSelected >= currentActions.length)
			curSelected = 0;

		var the:Int = 0;

		for (item in currentActions.members)
		{
			item.targetY = the - curSelected;
			item.scale.set(0.7, 0.7);
			item.alpha = 0.6;
			the++;

			if (item.ID == curSelected)
			{
				item.scale.set(0.9, 0.9);
				item.alpha = 1;
			}
		}

		return val;
	}

	private function set_curKeySelected(val:Int):Int
	{
		curKeySelected += val;

		if (curKeySelected < 0)
			curKeySelected = bindedActions.length - 1;
		if (curKeySelected >= bindedActions.length)
			curKeySelected = 0;

		var the:Int = 0;

		for (item in bindedActions.members)
		{
			item.targetY = the - curKeySelected;
			item.alpha = 0.4;
			the++;

			if (item.ID == curKeySelected)
				item.alpha = 1;
		}

		return val;
	}

	private function set_curActions(val:Int):Int
	{
		for (i in 0...currentActions.members.length)
		{
			currentActions.remove(currentActions.members[0], true);
		}

		curActions += val;

		if (curActions < 0)
			curActions = actions.length - 1;
		if (curActions >= actions.length)
			curActions = 0;

		regenActions(actions[curActions]);

		return val;
	}

	override function create()
	{
		instance = this;

		stage = new Stage("stage");
		add(stage);

		currentActions = new FlxTypedGroup<KeybindSelector>();
		bindedActions = new FlxTypedGroup<KeybindSelector>();
		add(bindedActions);
		add(currentActions);

		helpText = new KeybindSelector(0, 0, "Press ESC to cancel", FlxG.width - 40);
		helpText.forceX = 20;
		helpText.yMult = 0;
		helpText.yAdd = -225 - helpText.height;
		helpText.alpha = 0;
		add(helpText);

		curActions = 0;

		super.create();
	}

	// Sorry im more of a runtime mf
	private function regenActions(regenGroup:ActionType)
	{
		var i:Int = 0;
		var actionMap:StringMap<Array<Null<Int>>> = Reflect.field(Controls, regenGroup);
		for (action => keyArr in actionMap)
		{
			var newSelector:KeybindSelector = new KeybindSelector(0, (70 * i) + 30, '$action\nBinds: [${keyArr.length}]');
			var pos:Int = actionsOrder.get(action.split("_")[1]);
			newSelector.forceX = 30;
			newSelector.action = action;
			newSelector.targetY = pos;
			newSelector.ID = pos;
			currentActions.insert(pos, newSelector);
			i++;
		}
		curSelected = currentActions.length + 1;
	}

	private function regenBinded(object:KeybindSelector)
	{
		var i:Int = 0;
		var actionKeys:Array<Null<Int>> = Reflect.field(Controls, actions[curActions]).get(object.action);
		for (keyCode in actionKeys)
		{
			var newKeySelector:KeybindSelector = new KeybindSelector(0, (50 * i) + 10, 'Keybind ${i}: ', Std.int(object.width * 1.8), null,
				Controls.keyCodeToString(keyCode));
			newKeySelector.targetY = i;
			newKeySelector.ID = i;
			newKeySelector.baseKey = Controls.keyCodeToString(keyCode);
			newKeySelector.forceX = (FlxG.width / 2) - (object.width / 2);
			bindedActions.add(newKeySelector);
			i++;
		}
		curKeySelected = bindedActions.length + 1;
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (!canPress)
			return;

		switch (currentState)
		{
			case SELECTING:
				{
					switch (action)
					{
						case "ui_up":
							curSelected = -1;
						case "ui_down":
							curSelected = 1;
						case "ui_left":
							curActions = -1;
						case "ui_right":
							curActions = 1;
						case "confirm":
							{
								currentState = LISTING;
								canPress = false;
							}
						case "back":
							{
								SaveData.saveSettings();
								ScriptableState.switchState(new RewriteMenu());
							}
					}
				}
			case LISTING:
				{
					switch (action)
					{
						case "ui_up":
							curKeySelected = -1;
						case "ui_down":
							curKeySelected = 1;
						case "back":
							{
								currentState = SELECTING;
								canPress = false;
							}
						case "confirm":
							{
								currentState = WAITING;
								listening = true;
								canPress = false;
								if (bindedActions.members[curKeySelected].subBitText != null)
									bindedActions.members[curKeySelected].subBitText.text = "?";
							}
						case "reset":
							{
								var actionObject:KeybindSelector = currentActions.members[curSelected];
								var keyObject:KeybindSelector = bindedActions.members[curKeySelected];
								var actionMap:StringMap<Array<Null<Int>>> = Reflect.field(Controls, actions[curActions]);
								var defaultKey:String = Controls.keyCodeToString(Controls.defaultActions.get(actionObject.action)[keyObject.ID]);

								actionMap.get(actionObject.action)[keyObject.ID] = Controls.defaultActions.get(actionObject.action)[keyObject.ID];
								if (keyObject.subBitText != null)
									keyObject.subBitText.text = defaultKey;
							}
					}
				}
			case WAITING:
				{
					if (action == "back")
					{
						listening = false;
						currentState = LISTING;
						if (bindedActions.members[curKeySelected].subBitText != null)
							bindedActions.members[curKeySelected].subBitText.text = bindedActions.members[curKeySelected].baseKey;
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
		// keyCode 13 seems to be Enter/Return
		if (currentState == WAITING && listening == true && Controls.keyPressed.length > 0 && Controls.keyPressed[0] != 13)
		{
			var actionObject:KeybindSelector = currentActions.members[curSelected];
			var keyObject:KeybindSelector = bindedActions.members[curKeySelected];
			var newKey:Null<String> = Controls.keyCodeToString(Controls.keyPressed[0]);
			var actionMap:StringMap<Array<Null<Int>>> = Reflect.field(Controls, actions[curActions]);

			if (newKey == null)
			{
				keyObject.subBitText.text = keyObject.baseKey;
				return;
			}

			actionMap.get(actionObject.action)[keyObject.ID] = Controls.keyPressed[0];
			keyObject.subBitText.text = newKey;

			listening = false;
			currentState = LISTING;
		}

		super.update(elapsed);
	}
}

enum SelectionState
{
	SELECTING;
	LISTING;
	WAITING;
}
