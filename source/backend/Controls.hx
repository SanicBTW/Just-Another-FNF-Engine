package backend;

import flixel.FlxG;
import lime.app.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

enum ActionState
{
	PRESSED; // It has been pressed
	RELEASED; // It has been released
	IDLE; // Not initialized / pressed or released yet
}

enum abstract ActionType(String) to String
{
	var CONFIRM = "confirm";
	var BACK = "back";
	var RESET = "reset";
	var UI_LEFT = "ui_left";
	var UI_DOWN = "ui_down";
	var UI_UP = "ui_up";
	var UI_RIGHT = "ui_right";
	var NOTE_LEFT = "note_left";
	var NOTE_DOWN = "note_down";
	var NOTE_UP = "note_up";
	var NOTE_RIGHT = "note_right";
}

// Better? controls support (Static usage and non-static usage) (looks like the controls from fnf vanilla lmao)
class Controls
{
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

	// Base map which is used to get the keys in non-static variables
	private static var actions:Map<ActionType, Array<Null<Int>>> = [
		CONFIRM => [Keyboard.ENTER],
		BACK => [Keyboard.ESCAPE],
		RESET => [Keyboard.R],
		UI_LEFT => [Keyboard.LEFT, Keyboard.A],
		UI_DOWN => [Keyboard.DOWN, Keyboard.S],
		UI_UP => [Keyboard.UP, Keyboard.W],
		UI_RIGHT => [Keyboard.RIGHT, Keyboard.D],
		NOTE_LEFT => [Keyboard.LEFT, Keyboard.A, Keyboard.Z],
		NOTE_DOWN => [Keyboard.DOWN, Keyboard.S, Keyboard.X],
		NOTE_UP => [Keyboard.UP, Keyboard.W, Keyboard.COMMA],
		NOTE_RIGHT => [Keyboard.RIGHT, Keyboard.D, Keyboard.PERIOD]
	];

	// dont show this bad boy in intellisense
	@:noCompletion
	public static var keysPressed:Array<Int> = [];

	// system actions
	public var confirm(default, null):Action = new Action(CONFIRM);
	public var back(default, null):Action = new Action(BACK);
	public var reset(default, null):Action = new Action(RESET);

	// ui actions
	public var ui_left(default, null):Action = new Action(UI_LEFT);
	public var ui_down(default, null):Action = new Action(UI_DOWN);
	public var ui_up(default, null):Action = new Action(UI_UP);
	public var ui_right(default, null):Action = new Action(UI_RIGHT);

	// note actions
	public var note_left(default, null):Action = new Action(NOTE_LEFT);
	public var note_down(default, null):Action = new Action(NOTE_DOWN);
	public var note_up(default, null):Action = new Action(NOTE_UP);
	public var note_right(default, null):Action = new Action(NOTE_RIGHT);

	public function new() {}

	public static var onActionPressed:Event<ActionType->Void> = new Event<ActionType->Void>();
	public static var onActionReleased:Event<ActionType->Void> = new Event<ActionType->Void>();

	public static function Initialize()
	{
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

	public static function keyCodeToString(keyCode:Null<Int>):String
		return keyCode != null ? keyCodes.get(keyCode) : "None";

	private static function onKeyDown(evt:KeyboardEvent)
	{
		if (FlxG.keys.enabled && ((FlxG.state.active || FlxG.state.persistentUpdate)) && !keysPressed.contains(evt.keyCode))
		{
			keysPressed.push(evt.keyCode);

			// Get them name and keys
			for (name => keys in actions)
			{
				// Instead of creating a new object that contains keys and state and shit, just dispatch the action name
				if (keys.contains(evt.keyCode))
					onActionPressed.dispatch(name);
			}
		}
	}

	private static function onKeyUp(evt:KeyboardEvent)
	{
		if (FlxG.keys.enabled && ((FlxG.state.active || FlxG.state.persistentUpdate)) && keysPressed.contains(evt.keyCode))
		{
			keysPressed.remove(evt.keyCode);

			// Get them name and keys
			for (name => keys in actions)
			{
				// Instead of creating a new object that contains keys and state and shit, just dispatch the action name
				if (keys.contains(evt.keyCode))
					onActionReleased.dispatch(name);
			}
		}
	}
}

@:publicFields
class Action
{
	var name(default, null):ActionType;
	var state(get, null):ActionState;

	@:noCompletion
	private function get_state():ActionState
	{
		for (keyA in keys)
		{
			for (keyP in Controls.keysPressed)
			{
				if (keyA == keyP)
					return PRESSED;
			}
		}
		return RELEASED;
	}

	@:isVar var keys(get, set):Array<Null<Int>> = [];

	// internal
	@:noCompletion
	private var _ikeys:Array<Null<Int>> = [];

	// does it work properly??

	@:noCompletion
	private function get_keys():Array<Null<Int>>
	{
		@:privateAccess
		if (Controls.actions.exists(name))
			return Controls.actions.get(name);
		else
			return _ikeys;
	}

	@:noCompletion
	private function set_keys(newKeys:Null<Array<Null<Int>>>):Array<Null<Int>>
	{
		@:privateAccess
		if (Controls.actions.exists(name))
		{
			if (newKeys != null)
				Controls.actions.set(name, newKeys);
			else
				Controls.actions.set(name, keys);
		}
		else
			_ikeys = newKeys;

		return keys;
	}

	// private var _copycat:shaders.ShaderTesting.DeepCopy; idk if copy cat its necessary here prob for defaults
	// streamlined the process more
	// what the fuck did i do here - 3 days later since i rewrote the code
	function new(name:ActionType, state:ActionState = IDLE, keys:Null<Array<Null<Int>>> = null)
	{
		this.name = name;
		this.state = state;
		this._ikeys = this.keys;
		this.keys = keys;
	}
}
