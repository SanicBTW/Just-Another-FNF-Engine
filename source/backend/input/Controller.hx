package backend.input;

import backend.input.Controls;
import flixel.math.FlxMath;
import lime.ui.Gamepad;
import lime.ui.GamepadAxis;
import lime.ui.GamepadButton;

// Custom made to know the real direction where the gamepad axis is moving to

enum GamepadAxisDirection
{
	LEFT;
	RIGHT;
	UP;
	DOWN;
}

// Which schema should the engine use to represent the gamepad buttons

enum abstract GamepadType(String) to String from String
{
	var XBOX = "xbox";
	var PS4 = "ps4";
}

// Manages Gamepad shit, has some old code which was impossible to improve (imo)
class Controller
{
	private static var input:Null<Gamepad> = null;
	public static var type:GamepadType = XBOX; // We don't know which one is it so we just going with makin xbox the default one

	// bro what
	public static function rawIntToButton(int:Null<Int>):GamepadButton
		return cast int;

	// Realized GamepadButtons are integers too
	private static var actions:Map<ActionType, Array<Null<Int>>> = [
		CONFIRM => [GamepadButton.START, GamepadButton.A],
		BACK => [GamepadButton.BACK, GamepadButton.B],
		RESET => [null], // What do I assign this to
		PAUSE => [GamepadButton.START],
		UI_LEFT => [GamepadButton.DPAD_LEFT],
		UI_DOWN => [GamepadButton.DPAD_DOWN],
		UI_UP => [GamepadButton.DPAD_UP],
		UI_RIGHT => [GamepadButton.DPAD_RIGHT],
		NOTE_LEFT => [GamepadButton.DPAD_LEFT, GamepadButton.X],
		NOTE_DOWN => [GamepadButton.DPAD_DOWN, GamepadButton.A],
		NOTE_UP => [GamepadButton.DPAD_UP, GamepadButton.Y],
		NOTE_RIGHT => [GamepadButton.DPAD_RIGHT, GamepadButton.B]
	];
	private static var _defaultActions:Map<ActionType, Array<Null<Int>>> = actions.copy();

	public static var buttonsPressed:Array<Int> = [];

	// Needed for axis
	private static var movingAxes:Array<GamepadAxisDirection> = [];
	public static var deadzone:Float = 0.35;

	public static function setup()
	{
		checkConnections();

		Gamepad.onConnect.add(connect);
	}

	// Used to get the first Gamepad connected an dispatch the function to set it up
	// Only used on startup and when the connected gamepad gets disconnected, making it try to refresh the current one
	private static function checkConnections():Void
	{
		// If any connected before game startup, get the first one
		var gamepad:Null<Gamepad> = Gamepad.devices.get(0);
		if (gamepad != null)
			connect(gamepad);
	}

	// Events
	private static function connect(gamepad:Gamepad):Void
	{
		trace('Connected ${gamepad.name} [${gamepad.guid} | ${gamepad.id} | ${gamepad.connected}]');

		// DO NOT change the connected gamepad
		if (input != null)
		{
			trace('A gamepad is already registered (${input.name}), new one (${gamepad.name}) will not be set up');
			return;
		}

		input = gamepad;

		if (input.name.indexOf("PS4") > -1 || input.name.indexOf("DualShock 4") > -1)
			type = PS4;
		else
			type = XBOX;

		input.onDisconnect.add(disconnect);
		input.onAxisMove.add(axisMove);
		input.onButtonDown.add(buttonDown);
		input.onButtonUp.add(buttonUp);
	}

	private static function disconnect():Void
	{
		trace('Disconnected ${input.name} [${input.guid} | ${input.id} | ${input.connected}]');
		input = null;
		type = XBOX; // revert just in case
		checkConnections();
	}

	// Still uses the old code
	// Joystick movements SHOULD never be rebinded
	// Btw if both joysticks are being moved its a little bit weird
	private static function axisMove(axis:GamepadAxis, dist:Float):Void
	{
		switch (axis)
		{
			default:
				return;

			case TRIGGER_LEFT:
				var norm:Float = FlxMath.roundDecimal(dist, 2);
				if (!isIdle(norm))
				{
					detection(norm > deadzone, UI_LEFT, LEFT);
				}
				else
				{
					detection(true, UI_LEFT, LEFT, true);
				}

			case TRIGGER_RIGHT:
				var norm:Float = FlxMath.roundDecimal(dist, 2);
				if (!isIdle(norm))
				{
					detection(norm > deadzone, UI_RIGHT, RIGHT);
				}
				else
				{
					detection(true, UI_RIGHT, RIGHT, true);
				}

			case LEFT_X | RIGHT_X:
				var norm:Float = FlxMath.roundDecimal(dist, 2);
				if (!isIdle(norm))
				{
					detection(norm > deadzone, UI_RIGHT, RIGHT);
					detection(norm < -deadzone, UI_LEFT, LEFT);
				}
				else
				{
					// the axis is not moved, we force it to delete it
					detection(true, UI_RIGHT, RIGHT, true);
					detection(true, UI_LEFT, LEFT, true);
				}

			case LEFT_Y | RIGHT_Y:
				var norm:Float = FlxMath.roundDecimal(dist, 2);

				if (!isIdle(norm))
				{
					detection(norm > deadzone, UI_DOWN, DOWN);
					detection(norm < -deadzone, UI_UP, UP);
				}
				else
				{
					detection(true, UI_DOWN, DOWN, true);
					detection(true, UI_UP, UP, true);
				}
		}
	}

	private static function buttonDown(button:GamepadButton):Void
	{
		if (!buttonsPressed.contains(button))
		{
			buttonsPressed.push(button);

			for (action => buttons in actions)
			{
				if (buttons.contains(button))
					Controls.dispatchPressed(action);
			}
		}
	}

	private static function buttonUp(button:GamepadButton):Void
	{
		if (buttonsPressed.contains(button))
		{
			buttonsPressed.remove(button);

			for (action => buttons in actions)
			{
				if (buttons.contains(button))
					Controls.dispatchReleased(action);
			}
		}
	}

	// Utils for axis
	private static inline function isIdle(norm:Float):Bool
		return (Math.abs(norm) < deadzone);

	// Straight copy from the old code
	private static function detection(condition:Bool, action:ActionType, toDir:GamepadAxisDirection, delete:Bool = false):Void
	{
		var check:Bool = delete ? movingAxes.contains(toDir) : !movingAxes.contains(toDir);
		if (condition && check)
		{
			if (delete)
			{
				movingAxes.remove(toDir);
				Controls.dispatchReleased(action);
			}
			else
			{
				movingAxes.push(toDir);
				Controls.dispatchPressed(action);
			}
		}
	}
}
