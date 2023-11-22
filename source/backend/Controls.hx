package backend;

import flixel.FlxG;
import flixel.math.FlxMath;
import lime.app.Event;
import lime.ui.Gamepad;
import lime.ui.GamepadAxis;
import lime.ui.GamepadButton;
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

// Custom made to know the real direction where the gamepad axis is moving to
// isnt it too obvious by the names?
enum GamepadAxisDirection
{
	LEFT_X;
	RIGHT_X;
	UP_Y;
	DOWN_Y;
}

// Better? controls support (Static usage and non-static usage) (looks like the controls from fnf vanilla lmao)
class ControlsV2
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

	// Base map which is used to get the keys in non-static variables and dispatching the events
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

	// Base map which is used to get the gamepad buttons in non-static variables and dispatching the events
	// TODO: when entering a state that requires some bindings that are inside a ui specific action unbind it to make the note action work properly
	private static var gamepadActions:Map<ActionType, Array<Null<GamepadButton>>> = [
		CONFIRM => [GamepadButton.START],
		BACK => [GamepadButton.BACK],
		RESET => [null],
		UI_LEFT => [GamepadButton.DPAD_LEFT],
		UI_DOWN => [GamepadButton.DPAD_DOWN],
		UI_UP => [GamepadButton.DPAD_UP],
		UI_RIGHT => [GamepadButton.DPAD_RIGHT],
		NOTE_LEFT => [GamepadButton.DPAD_LEFT, GamepadButton.X],
		NOTE_DOWN => [GamepadButton.DPAD_DOWN, GamepadButton.A],
		NOTE_UP => [GamepadButton.DPAD_UP, GamepadButton.Y],
		NOTE_RIGHT => [GamepadButton.DPAD_RIGHT, GamepadButton.B]
	];

	// dont show this bad boy in intellisense
	@:noCompletion
	public static var keysPressed:Array<Int> = [];

	// sorry for this but prob the best way
	@:noCompletion
	public static var buttonsPressed:Array<GamepadButton> = [];

	// workaround to check if an axis is moving or currently controlled
	@:noCompletion
	public static var movingAxes:Array<GamepadAxisDirection> = [];

	// system actions
	public var confirm(default, null):Action = new Action(CONFIRM);
	public var back(default, null):Action = new Action(BACK);
	public var reset(default, null):Action = new Action(RESET);

	// ui actions
	public var ui_left(default, null):Action = new Action(UI_LEFT, true);
	public var ui_down(default, null):Action = new Action(UI_DOWN, true);
	public var ui_up(default, null):Action = new Action(UI_UP, true);
	public var ui_right(default, null):Action = new Action(UI_RIGHT, true);

	// note actions
	public var note_left(default, null):Action = new Action(NOTE_LEFT);
	public var note_down(default, null):Action = new Action(NOTE_DOWN);
	public var note_up(default, null):Action = new Action(NOTE_UP);
	public var note_right(default, null):Action = new Action(NOTE_RIGHT);

	public function new() {}

	public static var onActionPressed:Event<ActionType->Void> = new Event<ActionType->Void>();
	public static var onActionReleased:Event<ActionType->Void> = new Event<ActionType->Void>();

	private static var connectedGamepad:Null<Gamepad> = null;
	private static var deadZone:Float = 0.25;

	public static function Initialize()
	{
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);

		Gamepad.onConnect.add(onGamepadConnect);

		// only select the first one
		var gamepad:Null<Gamepad> = Gamepad.devices.get(0);
		if (gamepad != null)
			Gamepad.onConnect.dispatch(gamepad);
	}

	public static function keyCodeToString(keyCode:Null<Int>):String
		return keyCode != null ? keyCodes.get(keyCode) : "None";

	// KEYS
	private static function onKeyDown(evt:KeyboardEvent)
	{
		if (FlxG.keys.enabled && (FlxG.state.active || FlxG.state.persistentUpdate) && !keysPressed.contains(evt.keyCode))
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
		if (FlxG.keys.enabled && (FlxG.state.active || FlxG.state.persistentUpdate) && keysPressed.contains(evt.keyCode))
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

	// GAMEPADS
	private static function onGamepadConnect(gamepad:Gamepad):Void
	{
		connectedGamepad = gamepad;

		gamepad.onDisconnect.add(() ->
		{
			connectedGamepad = null;
			trace('Gamepad ${gamepad.name} disconnected');
		});

		// forced bindings, only for ui actions
		gamepad.onAxisMove.add((axis:GamepadAxis, dist:Float) ->
		{
			switch (axis)
			{
				case LEFT_X:
					var norm:Float = FlxMath.roundDecimal(dist, 2);

					if (!isIdle(norm))
					{
						checkAndPush(norm > deadZone, UI_RIGHT, RIGHT_X);
						checkAndPush(norm < -deadZone, UI_LEFT, LEFT_X);
					}
					else
					{
						// the axis is not moved, we force it to delete it
						checkAndPush(true, UI_RIGHT, RIGHT_X, true);
						checkAndPush(true, UI_LEFT, LEFT_X, true);
					}
				case LEFT_Y:
					var norm:Float = FlxMath.roundDecimal(dist, 2);

					if (!isIdle(norm))
					{
						checkAndPush(norm > deadZone, UI_DOWN, DOWN_Y);
						checkAndPush(norm < -deadZone, UI_UP, UP_Y);
					}
					else
					{
						checkAndPush(true, UI_DOWN, DOWN_Y, true);
						checkAndPush(true, UI_UP, UP_Y, true);
					}

				default:
					return;
			}
		});

		// Follows the same onKeyUp/onKeyDown functions
		gamepad.onButtonDown.add((button:GamepadButton) ->
		{
			// gampead.connected :skull:
			if (gamepad.connected && (FlxG.state.active || FlxG.state.persistentUpdate) && !buttonsPressed.contains(button))
			{
				buttonsPressed.push(button);

				// Get them name and keys
				for (name => buttons in gamepadActions)
				{
					// Instead of creating a new object that contains keys and state and shit, just dispatch the action name
					if (buttons.contains(button))
						onActionPressed.dispatch(name);
				}
			}
		});

		gamepad.onButtonUp.add((button:GamepadButton) ->
		{
			if (gamepad.connected && (FlxG.state.active || FlxG.state.persistentUpdate) && buttonsPressed.contains(button))
			{
				buttonsPressed.remove(button);

				// Get them name and keys
				for (name => buttons in gamepadActions)
				{
					// Instead of creating a new object that contains keys and state and shit, just dispatch the action name
					if (buttons.contains(button))
						onActionReleased.dispatch(name);
				}
			}
		});
	}

	// Gamepad utils
	private static function isIdle(norm:Float):Bool
		return (Math.abs(norm) < deadZone);

	private static function checkAndPush(condition:Bool, action:ActionType, toDir:GamepadAxisDirection, delete:Bool = false)
	{
		// js is such a baby "Can't create closure on an extern inline member method" :nerd:
		#if !js var arrfunc:(x:GamepadAxisDirection) -> Any = delete ? movingAxes.remove : movingAxes.push; #end
		var ev:Event<ActionType->Void> = delete ? onActionReleased : onActionPressed;
		var check:Bool = delete ? movingAxes.contains(toDir) : !movingAxes.contains(toDir);
		if (condition && check)
		{
			#if !js arrfunc(toDir); #end
			#if js
			if (delete)
				movingAxes.remove(toDir);
			else
				movingAxes.push(toDir);
			#end
			ev.dispatch(action);
		}
	}
}

// WILL probably rewrite sometime to clean the code

@:publicFields
class Action
{
	var name(default, null):ActionType;
	var state(get, null):ActionState;

	@:noCompletion
	private function get_state():ActionState
	{
		@:privateAccess
		if (ControlsV2.connectedGamepad != null)
		{
			var state:ActionState = quickCheck(buttons, ControlsV2.buttonsPressed) ? PRESSED : RELEASED;
			// forced and not checking, i know where im giving perms to act on axis, also is a  fallback)? for the standard buttons
			if (actsOnAxis && state == RELEASED)
			{
				switch (name)
				{
					case UI_LEFT:
						state = quickCheck([GamepadAxisDirection.LEFT_X], ControlsV2.movingAxes) ? PRESSED : RELEASED;

					case UI_RIGHT:
						state = quickCheck([GamepadAxisDirection.RIGHT_X], ControlsV2.movingAxes) ? PRESSED : RELEASED;

					case UI_UP:
						state = quickCheck([GamepadAxisDirection.UP_Y], ControlsV2.movingAxes) ? PRESSED : RELEASED;

					case UI_DOWN:
						state = quickCheck([GamepadAxisDirection.DOWN_Y], ControlsV2.movingAxes) ? PRESSED : RELEASED;

					default:
				}
			}

			return state;
		}
		else
			return quickCheck(keys, ControlsV2.keysPressed) ? PRESSED : RELEASED;

		return RELEASED;
	}

	private function quickCheck(data:Array<Any>, onArray:Array<Any>):Bool
	{
		for (value in data)
		{
			return onArray.indexOf(value) > -1;
		}

		return false;
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
		if (ControlsV2.actions.exists(name))
			return ControlsV2.actions.get(name);
		else
			return _ikeys;
	}

	@:noCompletion
	private function set_keys(newKeys:Null<Array<Null<Int>>>):Array<Null<Int>>
	{
		@:privateAccess
		if (ControlsV2.actions.exists(name))
		{
			if (newKeys != null)
				ControlsV2.actions.set(name, newKeys);
			else
				ControlsV2.actions.set(name, keys);
		}
		else
			_ikeys = newKeys;

		return keys;
	}

	var actsOnAxis:Bool = false;
	@:isVar var buttons(get, set):Array<Null<GamepadButton>> = [];

	// internal
	@:noCompletion
	private var _ibuttons:Array<Null<GamepadButton>> = [];

	// does it work properly?? - such a copy paste lmfao

	@:noCompletion
	private function get_buttons():Array<Null<GamepadButton>>
	{
		@:privateAccess
		if (ControlsV2.gamepadActions.exists(name))
			return ControlsV2.gamepadActions.get(name);
		else
			return _ibuttons;
	}

	@:noCompletion
	private function set_buttons(newButtons:Null<Array<Null<GamepadButton>>>):Array<Null<GamepadButton>>
	{
		@:privateAccess
		if (ControlsV2.gamepadActions.exists(name))
		{
			if (newButtons != null)
				ControlsV2.gamepadActions.set(name, newButtons);
			else
				ControlsV2.gamepadActions.set(name, buttons);
		}
		else
			_ibuttons = newButtons;

		return buttons;
	}

	// private var _copycat:shaders.ShaderTesting.DeepCopy; idk if copy cat its necessary here prob for defaults
	// streamlined the process more
	// what the fuck did i do here - 3 days later since i rewrote the code
	// if acts on axis, it will also check movingAxis array on the given action
	function new(name:ActionType, actsOnAxis:Bool = false, state:ActionState = IDLE, keys:Null<Array<Null<Int>>> = null,
			buttons:Null<Array<Null<GamepadButton>>> = null)
	{
		this.name = name;
		this.state = state;

		this._ikeys = this.keys;
		this._ibuttons = this.buttons;

		this.keys = keys;
		this.buttons = buttons;
		this.actsOnAxis = actsOnAxis;
	}
}
