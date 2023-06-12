package backend;

import flixel.FlxG;
import flixel.util.FlxSignal.FlxTypedSignal;
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
	var LEFT = "left";
	var DOWN = "down";
	var UP = "up";
	var RIGHT = "right";
}

// Better? controls support (Static usage and non-static usage) (looks like the controls from fnf vanilla lmao)
class Controls
{
	// Base map which is used to get the keys in non-static variables
	private static var actions:Map<ActionType, Array<Null<Int>>> = [
		CONFIRM => [Keyboard.ENTER],
		BACK => [Keyboard.ESCAPE],
		RESET => [Keyboard.R],
		LEFT => [Keyboard.LEFT, Keyboard.A],
		DOWN => [Keyboard.DOWN, Keyboard.S],
		UP => [Keyboard.UP, Keyboard.W],
		RIGHT => [Keyboard.RIGHT, Keyboard.D]
	];

	private static var keysPressed:Array<Int> = [];

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

	public var left(get, null):Action = {
		name: LEFT,
		state: IDLE,
		keys: actions.get(LEFT)
	};

	@:noCompletion
	private function get_left():Action
	{
		return {
			name: LEFT,
			state: FlxG.keys.anyPressed(left.keys) ? PRESSED : RELEASED,
			keys: left.keys
		};
	}

	public var down(get, null):Action = {
		name: DOWN,
		state: IDLE,
		keys: actions.get(DOWN)
	};

	@:noCompletion
	private function get_down():Action
	{
		return {
			name: DOWN,
			state: FlxG.keys.anyPressed(down.keys) ? PRESSED : RELEASED,
			keys: down.keys
		};
	}

	public var up(get, null):Action = {
		name: UP,
		state: IDLE,
		keys: actions.get(UP)
	};

	@:noCompletion
	private function get_up():Action
	{
		return {
			name: UP,
			state: FlxG.keys.anyPressed(up.keys) ? PRESSED : RELEASED,
			keys: up.keys
		};
	}

	public var right(get, null):Action = {
		name: RIGHT,
		state: IDLE,
		keys: actions.get(RIGHT)
	};

	@:noCompletion
	private function get_right():Action
	{
		return {
			name: RIGHT,
			state: FlxG.keys.anyPressed(right.keys) ? PRESSED : RELEASED,
			keys: right.keys
		};
	}

	public function new() {}

	public static var onActionPressed:FlxTypedSignal<ActionType->Void> = new FlxTypedSignal<ActionType->Void>();
	public static var onActionReleased:FlxTypedSignal<ActionType->Void> = new FlxTypedSignal<ActionType->Void>();

	public static function Init()
	{
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
