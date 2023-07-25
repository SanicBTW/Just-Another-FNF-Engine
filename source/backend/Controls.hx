package backend;

import backend.Event.EventGroup;
import flixel.FlxG;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

typedef Action =
{
	var name:ActionType;
	var state:ActionState;
	var keys:Array<Null<Int>>;
}

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
// On property getter, change the original variable shit for Reflect to work and not return IDLE
class Controls
{
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

	private static var keysPressed:Array<Int> = [];

	// system actions
	public var confirm(get, null):Action = {
		name: CONFIRM,
		state: IDLE,
		keys: actions.get(CONFIRM)
	};

	@:noCompletion
	private function get_confirm():Action
	{
		return {
			name: CONFIRM,
			state: FlxG.keys.anyPressed(confirm.keys) ? PRESSED : RELEASED,
			keys: confirm.keys
		};
	}

	public var back(get, null):Action = {
		name: BACK,
		state: IDLE,
		keys: actions.get(BACK)
	};

	@:noCompletion
	private function get_back():Action
	{
		return {
			name: BACK,
			state: FlxG.keys.anyPressed(back.keys) ? PRESSED : RELEASED,
			keys: back.keys
		};
	}

	public var reset(get, null):Action = {
		name: RESET,
		state: IDLE,
		keys: actions.get(RESET)
	};

	@:noCompletion
	private function get_reset():Action
	{
		return {
			name: RESET,
			state: FlxG.keys.anyPressed(reset.keys) ? PRESSED : RELEASED,
			keys: reset.keys
		};
	}

	// ui actions
	public var ui_left(get, null):Action = {
		name: UI_LEFT,
		state: IDLE,
		keys: actions.get(UI_LEFT)
	};

	@:noCompletion
	private function get_ui_left():Action
	{
		return {
			name: UI_LEFT,
			state: FlxG.keys.anyPressed(ui_left.keys) ? PRESSED : RELEASED,
			keys: ui_left.keys
		};
	}

	public var ui_down(get, null):Action = {
		name: UI_DOWN,
		state: IDLE,
		keys: actions.get(UI_DOWN)
	};

	@:noCompletion
	private function get_ui_down():Action
	{
		return {
			name: UI_DOWN,
			state: FlxG.keys.anyPressed(ui_down.keys) ? PRESSED : RELEASED,
			keys: ui_down.keys
		};
	}

	public var ui_up(get, null):Action = {
		name: UI_UP,
		state: IDLE,
		keys: actions.get(UI_UP)
	};

	@:noCompletion
	private function get_ui_up():Action
	{
		return {
			name: UI_UP,
			state: FlxG.keys.anyPressed(ui_up.keys) ? PRESSED : RELEASED,
			keys: ui_up.keys
		};
	}

	public var ui_right(get, null):Action = {
		name: UI_RIGHT,
		state: IDLE,
		keys: actions.get(UI_RIGHT)
	};

	@:noCompletion
	private function get_ui_right():Action
	{
		return {
			name: UI_RIGHT,
			state: FlxG.keys.anyPressed(ui_right.keys) ? PRESSED : RELEASED,
			keys: ui_right.keys
		};
	}

	// note actions
	public var note_left(get, null):Action = {
		name: NOTE_LEFT,
		state: IDLE,
		keys: actions.get(NOTE_LEFT)
	};

	@:noCompletion
	private function get_note_left():Action
	{
		return {
			name: NOTE_LEFT,
			state: FlxG.keys.anyPressed(note_left.keys) ? PRESSED : RELEASED,
			keys: note_left.keys
		};
	}

	public var note_down(get, null):Action = {
		name: NOTE_DOWN,
		state: IDLE,
		keys: actions.get(NOTE_DOWN)
	};

	@:noCompletion
	private function get_note_down():Action
	{
		return {
			name: NOTE_DOWN,
			state: FlxG.keys.anyPressed(note_down.keys) ? PRESSED : RELEASED,
			keys: note_down.keys
		};
	}

	public var note_up(get, null):Action = {
		name: NOTE_UP,
		state: IDLE,
		keys: actions.get(NOTE_UP)
	};

	@:noCompletion
	private function get_note_up():Action
	{
		return {
			name: NOTE_UP,
			state: FlxG.keys.anyPressed(note_up.keys) ? PRESSED : RELEASED,
			keys: note_up.keys
		};
	}

	public var note_right(get, null):Action = {
		name: NOTE_RIGHT,
		state: IDLE,
		keys: actions.get(NOTE_RIGHT)
	};

	@:noCompletion
	private function get_note_right():Action
	{
		return {
			name: NOTE_RIGHT,
			state: FlxG.keys.anyPressed(note_right.keys) ? PRESSED : RELEASED,
			keys: note_right.keys
		};
	}

	public function new() {}

	public static var onActionEvent:EventGroup<ActionType> = new EventGroup<ActionType>();

	public static function Initialize()
	{
		onActionEvent.addEvent('onActionPressed');
		onActionEvent.addEvent('onActionReleased');

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

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
					onActionEvent.triggerEvent("onActionPressed", name);
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
					onActionEvent.triggerEvent("onActionReleased", name);
			}
		}
	}
}
