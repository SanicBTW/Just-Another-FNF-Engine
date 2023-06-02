package backend;

import flixel.FlxG;
import flixel.util.FlxSignal;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

// Originally from FNF-Forever-Engine (My fork)
// Slightly modified
class Controls
{
	// Events
	public static var onActionPressed:FlxTypedSignal<Action->Void> = new FlxTypedSignal<Action->Void>();
	public static var onActionReleased:FlxTypedSignal<Action->Void> = new FlxTypedSignal<Action->Void>();

	// Key codes obviously lol
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

	// Keys being held
	public static var keysPressed:Array<Int> = [];

	// Which actions we are tracking
	public static var targetActions:ActionMap = UI;

	// System Actions
	private static var systemActions:Map<Action, Array<Null<Int>>> = [CONFIRM => [Keyboard.ENTER], BACK => [Keyboard.ESCAPE], RESET => [Keyboard.R],];

	// Default System Actions
	@:noCompletion
	private static var default_systemActions:Map<Action, Array<Null<Int>>> = systemActions.copy();

	// UI Actions
	private static var uiActions:Map<Action, Array<Null<Int>>> = [
		UI_LEFT => [Keyboard.LEFT, Keyboard.A],
		UI_DOWN => [Keyboard.DOWN, Keyboard.S],
		UI_UP => [Keyboard.UP, Keyboard.W],
		UI_RIGHT => [Keyboard.RIGHT, Keyboard.D],
	];

	// Default UI Actions
	@:noCompletion
	private static var default_uiActions:Map<Action, Array<Null<Int>>> = uiActions.copy();

	// Note Actions
	private static var noteActions:Map<Action, Array<Null<Int>>> = [
		NOTE_LEFT => [Keyboard.LEFT, Keyboard.A, Keyboard.Z],
		NOTE_DOWN => [Keyboard.DOWN, Keyboard.S, Keyboard.X],
		NOTE_UP => [Keyboard.UP, Keyboard.W, Keyboard.COMMA],
		NOTE_RIGHT => [Keyboard.RIGHT, Keyboard.D, Keyboard.PERIOD],
	];

	// Default Note Actions
	@:noCompletion
	private static var default_noteActions:Map<Action, Array<Null<Int>>> = noteActions.copy();

	// Add the key listeners
	public static function Initialize()
	{
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

	// Why would someone want to get if a system action is being pressed
	public static function isActionPressed(action:Action):Bool
	{
		if (!FlxG.keys.enabled && !(FlxG.state.active || FlxG.state.persistentUpdate))
			return false;

		var targetMap:Map<Action, Array<Null<Int>>> = Reflect.field(Controls, targetActions);

		if (!targetMap.exists(action))
			return false;

		for (key in targetMap.get(action))
		{
			for (pKey in keysPressed)
			{
				if (key == pKey)
					return true;
			}
		}
		return false;
	}

	// TODO: See another way to get this done
	public static function getActionFromKey(key:Int):Null<Action>
	{
		var targetMap:Map<Action, Array<Null<Int>>> = Reflect.field(Controls, targetActions);

		// Check the system actions
		for (actionName => actionKeys in systemActions)
		{
			for (actionKey in actionKeys)
			{
				if (actionKey == key)
					return actionName;
			}
		}

		// Then check the target map
		for (actionName => actionKeys in targetMap)
		{
			for (actionKey in actionKeys)
			{
				if (actionKey == key)
					return actionName;
			}
		}
		return null;
	}

	// bruuuuuuuuuuuuuuh
	private static function onKeyDown(evt:KeyboardEvent)
	{
		if (FlxG.keys.enabled
			&& ((FlxG.state.active || FlxG.state.persistentUpdate)
				|| (FlxG.state.subState != null && (FlxG.state.subState.active || FlxG.state.subState.persistentUpdate))))
		{
			if (!keysPressed.contains(evt.keyCode))
			{
				keysPressed.push(evt.keyCode);
				var pressedAction:Null<Action> = getActionFromKey(evt.keyCode);
				if (pressedAction != null)
					onActionPressed.dispatch(pressedAction);
			}
		}
	}

	private static function onKeyUp(evt:KeyboardEvent)
	{
		if (FlxG.keys.enabled
			&& ((FlxG.state.active || FlxG.state.persistentUpdate)
				|| (FlxG.state.subState != null && (FlxG.state.subState.active || FlxG.state.subState.persistentUpdate))))
		{
			if (keysPressed.contains(evt.keyCode))
			{
				keysPressed.remove(evt.keyCode);
				var releasedAction:Null<Action> = getActionFromKey(evt.keyCode);
				if (releasedAction != null)
					onActionReleased.dispatch(releasedAction);
			}
		}
	}
}

// I just couldn't find any other way sorry :pray:
enum abstract ActionMap(String) to String
{
	var UI = "uiActions";
	var NOTES = "noteActions";
}

enum abstract Action(String) to String
{
	// System
	var CONFIRM = "confirm";
	var BACK = "back";
	var RESET = "reset";
	// UI
	var UI_LEFT = "ui_left";
	var UI_DOWN = "ui_down";
	var UI_UP = "ui_up";
	var UI_RIGHT = "ui_right";
	// Notes
	var NOTE_LEFT = "note_left";
	var NOTE_DOWN = "note_down";
	var NOTE_UP = "note_up";
	var NOTE_RIGHT = "note_right";
}
