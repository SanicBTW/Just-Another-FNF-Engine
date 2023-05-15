package backend;

import flixel.FlxG;
import flixel.util.FlxSignal;
import haxe.ds.StringMap;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

// Originally from FNF-Forever-Engine (My fork)
// Slightly modified
// Saving is gonna be hell, also somehow made the code look way worse bruh
class Controls
{
	// Events
	public static var onActionPressed:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();
	public static var onActionReleased:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

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
	public static var targetActions:ActionType = UI;

	// Which note actions we are tracking (amount of keys that will be listened on note actions)
	public static var maniaTarget:ManiaSchema = K_4;

	// System Actions
	private static var systemActions:StringMap<Array<Null<Int>>> = [
		"confirm" => [Keyboard.ENTER],
		"back" => [Keyboard.ESCAPE],
		"reset" => [Keyboard.R],
	];

	// Default System Actions
	@:noCompletion
	private static var default_systemActions:StringMap<Array<Null<Int>>> = systemActions.copy();

	// UI Actions
	private static var uiActions:StringMap<Array<Null<Int>>> = [
		"ui_left" => [Keyboard.LEFT, Keyboard.A],
		"ui_down" => [Keyboard.DOWN, Keyboard.S],
		"ui_up" => [Keyboard.UP, Keyboard.W],
		"ui_right" => [Keyboard.RIGHT, Keyboard.D],
	];

	// Default UI Actions
	@:noCompletion
	private static var default_uiActions:StringMap<Array<Null<Int>>> = uiActions.copy();

	// Note Actions
	private static var noteActions:Map<ManiaSchema, StringMap<Array<Null<Int>>>> = [
		K_1 => ["special" => [Keyboard.SPACE]],
		K_2 => ["left" => [Keyboard.LEFT, Keyboard.A], "right" => [Keyboard.RIGHT, Keyboard.D]],
		K_3 => [
			"left" => [Keyboard.LEFT, Keyboard.A],
			"special" => [Keyboard.SPACE],
			"right" => [Keyboard.RIGHT, Keyboard.D]
		],
		K_4 => [
			"left" => [Keyboard.LEFT, Keyboard.A],
			"down" => [Keyboard.DOWN, Keyboard.S],
			"up" => [Keyboard.UP, Keyboard.W],
			"right" => [Keyboard.RIGHT, Keyboard.D],
		],
		K_5 => [
			"left" => [Keyboard.LEFT, Keyboard.A],
			"down" => [Keyboard.DOWN, Keyboard.S],
			"special" => [Keyboard.SPACE],
			"up" => [Keyboard.UP, Keyboard.W],
			"right" => [Keyboard.RIGHT, Keyboard.D],
		],
		// because forced alts might be weird ngl (dont know what to set lol)
		K_6 => [
			"left1" => [Keyboard.S],
			"down" => [Keyboard.D],
			"right1" => [Keyboard.F],
			"left2" => [Keyboard.J],
			"up" => [Keyboard.K],
			"right2" => [Keyboard.L],
		],
		K_7 => [
			"left1" => [Keyboard.S],
			"down" => [Keyboard.D],
			"right1" => [Keyboard.F],
			"special" => [Keyboard.SPACE],
			"left2" => [Keyboard.J],
			"up" => [Keyboard.K],
			"right2" => [Keyboard.L],
		],
		K_8 => [
			"left1" => [Keyboard.A],
			"down1" => [Keyboard.S],
			"up1" => [Keyboard.D],
			"right1" => [Keyboard.F],
			"left2" => [Keyboard.H],
			"down2" => [Keyboard.J],
			"up2" => [Keyboard.K],
			"right2" => [Keyboard.L],
		],
		K_9 => [
			"left1" => [Keyboard.A],
			"down1" => [Keyboard.S],
			"up1" => [Keyboard.D],
			"right1" => [Keyboard.F],
			"special" => [Keyboard.SPACE],
			"left2" => [Keyboard.H],
			"down2" => [Keyboard.J],
			"up2" => [Keyboard.K],
			"right2" => [Keyboard.L],
		],
	];

	// Default Note Actions
	@:noCompletion
	private static var default_noteActions:Map<ManiaSchema, StringMap<Array<Null<Int>>>> = noteActions.copy();

	// Add the key listeners
	public static function Initialize()
	{
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

	// Why would someone want to get if a system action is being pressed
	public static function isActionPressed(action:String):Bool
	{
		if (!FlxG.keys.enabled && !(FlxG.state.active || FlxG.state.persistentUpdate))
			return false;

		var targetMap:StringMap<Array<Null<Int>>> = (targetActions == NOTES) ? noteActions.get(maniaTarget) : uiActions;

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
	public static function getActionFromKey(key:Int):Null<String>
	{
		var targetMap:StringMap<Array<Null<Int>>> = (targetActions == NOTES) ? noteActions.get(maniaTarget) : uiActions;

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

	private static function onKeyDown(evt:KeyboardEvent)
	{
		if (FlxG.keys.enabled && (FlxG.state.active || FlxG.state.persistentUpdate))
		{
			if (!keysPressed.contains(evt.keyCode))
			{
				keysPressed.push(evt.keyCode);
				var pressedAction:Null<String> = getActionFromKey(evt.keyCode);
				if (pressedAction != null)
					onActionPressed.dispatch(pressedAction);
			}
		}
	}

	private static function onKeyUp(evt:KeyboardEvent)
	{
		if (FlxG.keys.enabled && (FlxG.state.active || FlxG.state.persistentUpdate))
		{
			if (keysPressed.contains(evt.keyCode))
			{
				keysPressed.remove(evt.keyCode);
				var releasedAction:Null<String> = getActionFromKey(evt.keyCode);
				if (releasedAction != null)
					onActionReleased.dispatch(releasedAction);
			}
		}
	}
}

// I just couldn't find any other way sorry :pray:
enum abstract ActionType(String) to String
{
	var UI = "uiActions";
	var NOTES = "noteActions";
}

// Kind of dumb actually but kinda useful
enum abstract ManiaSchema(String) to String
{
	var K_1 = "K_1";
	var K_2 = "K_2";
	var K_3 = "K_3";
	var K_4 = "K_4";
	var K_5 = "K_5";
	var K_6 = "K_6";
	var K_7 = "K_7";
	var K_8 = "K_8";
	var K_9 = "K_9";
}
