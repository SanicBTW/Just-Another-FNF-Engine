package base.system;

import base.system.SaveFile;
import flixel.FlxG;
import haxe.ds.StringMap;
import lime.app.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

// From FNF-Forever-Engine (My fork) - prob a rewrite coming soon (never probably)
class Controls
{
	public static var onActionPressed:Event<String->Void> = new Event<String->Void>();
	public static var onActionReleased:Event<String->Void> = new Event<String->Void>();

	private static final keyCodes:Map<Int, String> = [
		65 => "A", 66 => "B", 67 => "C", 68 => "D", 69 => "E", 70 => "F", 71 => "G", 72 => "H", 73 => "I", 74 => "J", 75 => "K", 76 => "L", 77 => "M",
		78 => "N", 79 => "O", 80 => "P", 81 => "Q", 82 => "R", 83 => "S", 84 => "T", 85 => "U", 86 => "V", 87 => "W", 88 => "X", 89 => "Y", 90 => "Z",
		48 => "0", 49 => "1", 50 => "2", 51 => "3", 52 => "4", 53 => "5", 54 => "6", 55 => "7", 56 => "8", 57 => "9", 33 => "Page Up", 34 => "Page Down",
		36 => "Home", 35 => "End", 45 => "Insert", 27 => "Escape", 189 => "-", 187 => "+", 46 => "Delete", 8 => "Backspace", 219 => "[", 221 => "]",
		220 => "\\", 20 => "Caps Lock", 186 => ";", 222 => "\"", 13 => "Enter", 16 => "Shift", 188 => ",", 190 => ".", 191 => "/", 192 => "`", 17 => "Ctrl",
		18 => "Alt", 32 => "Space", 38 => "Up", 40 => "Down", 37 => "Left", 39 => "Right", 9 => "Tab", 301 => "Print Screen", 112 => "F1", 113 => "F2",
		114 => "F3", 115 => "F4", 116 => "F5", 117 => "F6", 118 => "F7", 119 => "F8", 120 => "F9", 121 => "F10", 122 => "F11", 123 => "F12", 96 => "Numpad 0",
		97 => "Numpad 1", 98 => "Numpad 2", 99 => "Numpad 3", 100 => "Numpad 4", 101 => "Numpad 5", 102 => "Numpad 6", 103 => "Numpad 7", 104 => "Numpad 8",
		105 => "Numpad 9", 109 => "Numpad -", 107 => "Numpad +", 110 => "Numpad .", 106 => "Numpad *"
	];

	// System/Base/Global/Current Actions
	private static var actions:StringMap<Array<Null<Int>>> = [
		"confirm" => [Keyboard.ENTER],
		"back" => [Keyboard.ESCAPE],
		"reset" => [Keyboard.R],
		"fullscreen" => [Keyboard.F11]
	];

	// UI Actions
	public static var uiActions:StringMap<Array<Null<Int>>> = [
		"ui_left" => [Keyboard.LEFT, Keyboard.A],
		"ui_down" => [Keyboard.DOWN, Keyboard.S],
		"ui_up" => [Keyboard.UP, Keyboard.W],
		"ui_right" => [Keyboard.RIGHT, Keyboard.D],
	];

	// Note Actions
	public static var noteActions:StringMap<Array<Null<Int>>> = [
		"note_left" => [Keyboard.LEFT, Keyboard.A],
		"note_down" => [Keyboard.DOWN, Keyboard.S],
		"note_up" => [Keyboard.UP, Keyboard.W],
		"note_right" => [Keyboard.RIGHT, Keyboard.D],
	];

	// All the Actions together to restore them in the future
	public static var defaultActions:StringMap<Array<Null<Int>>> = [
		"ui_left" => [Keyboard.LEFT, Keyboard.A],
		"ui_down" => [Keyboard.DOWN, Keyboard.S],
		"ui_up" => [Keyboard.UP, Keyboard.W],
		"ui_right" => [Keyboard.RIGHT, Keyboard.D],
		"note_left" => [Keyboard.LEFT, Keyboard.A],
		"note_down" => [Keyboard.DOWN, Keyboard.S],
		"note_up" => [Keyboard.UP, Keyboard.W],
		"note_right" => [Keyboard.RIGHT, Keyboard.D],
	];

	public static var keyPressed:Array<Int> = [];

	public static function init()
	{
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		setActions(UI);
	}

	// Helper function to set actions to listen on key press
	public static function setActions(newActions:ActionType)
	{
		var mapToAdd = (newActions == UI ? uiActions : noteActions);
		var checkMap = (newActions == UI ? noteActions : uiActions);
		for (action in checkMap.keys())
		{
			if (actions.exists(action))
				actions.remove(action);
		}

		for (action => keys in mapToAdd)
		{
			if (!actions.exists(action))
				actions.set(action, keys);
		}
	}

	private static function checkActions()
	{
		for (action => keys in uiActions)
		{
			if (SaveFile.get('ui_action-$action') != null)
				return;

			trace('No ${action} action found');
			SaveFile.set('ui_action-$action', parseArray(keys));
		}

		for (action => keys in noteActions)
		{
			if (SaveFile.get('note_action-$action') != null)
				return;

			trace('No ${action} action found');
			SaveFile.set('note_action-$action', parseArray(keys));
		}
	}

	public static function saveActions()
	{
		for (action => keys in uiActions)
		{
			SaveFile.set('ui_action-$action', parseArray(keys));
		}

		for (action => keys in noteActions)
		{
			SaveFile.set('note_action-$action', parseArray(keys));
		}
	}

	public static function reloadActions()
	{
		checkActions();

		// Kind of dumb but it works :+1:
		for (action in uiActions.keys())
		{
			var rawLoad:Array<String> = SaveFile.get('ui_action-$action').split(",");
			var loadKeys:Array<Null<Int>> = [];
			for (key in rawLoad)
			{
				loadKeys.push(Std.parseInt(key));
			}
			uiActions.set(action, loadKeys);
		}

		for (action in noteActions.keys())
		{
			var rawLoad:Array<String> = SaveFile.get('note_action-$action').split(",");
			var loadKeys:Array<Null<Int>> = [];
			for (key in rawLoad)
			{
				loadKeys.push(Std.parseInt(key));
			}
			noteActions.set(action, loadKeys);
		}
	}

	public static function keyCodeToString(keyCode:Null<Int>):String
		return keyCode != null ? keyCodes.get(keyCode) : "None";

	public static function getActionFromKey(key:Int):Null<String>
	{
		for (actionName => actionKeys in actions)
		{
			for (actionKey in actionKeys)
			{
				if (key == actionKey)
					return actionName;
			}
		}
		return null;
	}

	private static function onKeyDown(evt:KeyboardEvent)
	{
		if (!keyPressed.contains(evt.keyCode))
		{
			keyPressed.push(evt.keyCode);

			var pressedAction:Null<String> = getActionFromKey(evt.keyCode);
			// I hate this so much but it's the only way
			if (pressedAction != null)
			{
				switch (pressedAction)
				{
					case "fullscreen":
						FlxG.fullscreen = !FlxG.fullscreen;
				}
				onActionPressed.dispatch(pressedAction);
			}
		}
	}

	private static function onKeyUp(evt:KeyboardEvent)
	{
		if (keyPressed.contains(evt.keyCode))
		{
			keyPressed.remove(evt.keyCode);

			var releasedAction:Null<String> = getActionFromKey(evt.keyCode);
			if (releasedAction != null)
				onActionReleased.dispatch(releasedAction);
		}
	}

	private static function parseArray(array:Array<Dynamic>):String
	{
		#if html5
		// dumb ass JS parses arrays correctly without leaving array brackets
		return array.toString();
		#else
		// native dumb ass platforms turns an array into a string including the brackets
		// First character is [ and we search the index of the end bracket
		return array.toString().substring(1, array.toString().indexOf("]"));
		#end
	}
}

enum abstract ActionType(String) to String
{
	var UI = "uiActions";
	var NOTES = "noteActions";
}
