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

// Manages Gamepad shit, has some old code which was impossible to improve (imo)
class Controller
{
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

	private static var input:Null<Gamepad> = null;

	// Needed for axis
	private static var movingAxes:Array<GamepadAxisDirection> = [];
	public static var deadzone:Float = 0.25;

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
		// DO NOT change the connected gamepad
		if (input == null)
			input = gamepad;

		trace('Connected ${input.name} [${input.guid} | ${input.id} | ${input.connected}]');

		gamepad.onDisconnect.add(disconnect);
		gamepad.onAxisMove.add(axisMove);
		gamepad.onButtonDown.add(buttonDown);
		gamepad.onButtonUp.add(buttonUp);
	}

	private static function disconnect():Void
	{
		trace('Disconnected ${input.name} [${input.guid} | ${input.id} | ${input.connected}]');
		input = null;
		checkConnections();
	}

	// Still uses the old code
	// Joystick movements SHOULD never be rebinded
	// TODO: Triggers
	private static function axisMove(axis:GamepadAxis, dist:Float):Void
	{
		switch (axis)
		{
			default:
				return;

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
		for (action => buttons in actions)
		{
			if (buttons.contains(button))
				Controls.dispatchPressed(action);
		}
	}

	private static function buttonUp(button:GamepadButton):Void
	{
		for (action => buttons in actions)
		{
			if (buttons.contains(button))
				Controls.dispatchReleased(action);
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
