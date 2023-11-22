package backend.input;

import backend.input.Controls;
import flixel.FlxG;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard as OKeyboard;

// Manages Key shit, probably the easiest shit I've done
// Controller has math included and it sucks :sob:
class Keyboard
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

	public static function keyCodeToString(keyCode:Null<Int>):String
		return keyCode != null ? keyCodes.get(keyCode) : "None";

	private static var actions:Map<ActionType, Array<Null<Int>>> = [
		CONFIRM => [OKeyboard.ENTER],
		BACK => [OKeyboard.ESCAPE],
		RESET => [OKeyboard.R],
		PAUSE => [OKeyboard.ESCAPE, OKeyboard.ENTER, OKeyboard.NUMPAD_ENTER],
		UI_LEFT => [OKeyboard.LEFT, OKeyboard.A],
		UI_DOWN => [OKeyboard.DOWN, OKeyboard.S],
		UI_UP => [OKeyboard.UP, OKeyboard.W],
		UI_RIGHT => [OKeyboard.RIGHT, OKeyboard.D],
		NOTE_LEFT => [OKeyboard.LEFT, OKeyboard.A, OKeyboard.Z],
		NOTE_DOWN => [OKeyboard.DOWN, OKeyboard.S, OKeyboard.X],
		NOTE_UP => [OKeyboard.UP, OKeyboard.W, OKeyboard.COMMA],
		NOTE_RIGHT => [OKeyboard.RIGHT, OKeyboard.D, OKeyboard.PERIOD]
	];

	public static function setup()
	{
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

	private static function onKeyDown(evt:KeyboardEvent)
	{
		for (action => keys in actions)
		{
			if (keys.contains(evt.keyCode))
				Controls.dispatchPressed(action);
		}
	}

	private static function onKeyUp(evt:KeyboardEvent)
	{
		for (action => keys in actions)
		{
			if (keys.contains(evt.keyCode))
				Controls.dispatchReleased(action);
		}
	}
}
