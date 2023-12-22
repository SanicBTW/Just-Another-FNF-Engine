package backend.input;

import backend.input.*;
import flixel.FlxG;
import funkin.states.*;
import lime.app.Event;
import quaver.states.*;

// Wrapper to join both Keyboard.hx and Controller.hx
// Each file contains code to manage its own shit so its easier now
// Used as a switch on which Actions are we currently listening
enum Actors
{
	UI; // All UI_ Prefixed Actions including "Confirm", "Back" and "Reset"
	NOTE; // All NOTE_ Prefixed Actions including "Reset" and "Pause"
	NONE; // Any keybind that is pressed WONT be dispatched, this one has to be set manually
}

// Realized that IDLE is stupid since I can always return RELEASED for fresh Actions
enum ActionState
{
	PRESSED; // It has been pressed
	RELEASED; // It has been released
}

// Available Actions - Had to uppercase it cuz of Reflection
enum abstract ActionType(String) to String
{
	var CONFIRM = "CONFIRM";
	var BACK = "BACK";
	var RESET = "RESET";
	var PAUSE = "PAUSE";
	var UI_LEFT = "UI_LEFT";
	var UI_DOWN = "UI_DOWN";
	var UI_UP = "UI_UP";
	var UI_RIGHT = "UI_RIGHT";
	var NOTE_LEFT = "NOTE_LEFT";
	var NOTE_DOWN = "NOTE_DOWN";
	var NOTE_UP = "NOTE_UP";
	var NOTE_RIGHT = "NOTE_RIGHT";
}

// Joining them in a single object since its easier to load and save in a single call
typedef SavedAction =
{
	var gpBinds:Array<Null<Int>>; // Gamepad Binds, at first I thought on makin them GamepadButtons but that's dumb
	var kbBinds:Array<Null<Int>>; // Keyboard Binds, jus the same as always
}

// Controls V3 - Surely the last rewrite I'm going to make to the input
class Controls
{
	// ui actions
	public var CONFIRM(default, null):Action = new Action(ActionType.CONFIRM);
	public var BACK(default, null):Action = new Action(ActionType.BACK);
	public var UI_LEFT(default, null):Action = new Action(ActionType.UI_LEFT);
	public var UI_DOWN(default, null):Action = new Action(ActionType.UI_DOWN);
	public var UI_UP(default, null):Action = new Action(ActionType.UI_UP);
	public var UI_RIGHT(default, null):Action = new Action(ActionType.UI_RIGHT);

	// note actions
	public var PAUSE(default, null):Action = new Action(ActionType.PAUSE);
	public var RESET(default, null):Action = new Action(ActionType.RESET);
	public var NOTE_LEFT(default, null):Action = new Action(ActionType.NOTE_LEFT);
	public var NOTE_DOWN(default, null):Action = new Action(ActionType.NOTE_DOWN);
	public var NOTE_UP(default, null):Action = new Action(ActionType.NOTE_UP);
	public var NOTE_RIGHT(default, null):Action = new Action(ActionType.NOTE_RIGHT);

	public function new() {}

	// TODO: Improve check
	// This switch only works on static exposure and is not applied on the object exposure
	// This is just the same as the older versions of JAFE but now automatic
	private static var actor:Actors = UI;

	// When switching states, the code will try to automatically switch the actor to avoid issues and manual override
	public static var uiStates:Array<String> = [];
	public static var noteStates:Array<String> = [Type.getClassName(QuaverGameplay), Type.getClassName(PlayState)];

	public static var onActionPressed:Event<ActionType->Void> = new Event<ActionType->Void>();
	public static var onActionReleased:Event<ActionType->Void> = new Event<ActionType->Void>();

	public static function Initialize()
	{
		Controller.setup();
		Keyboard.setup();

		// the fuck??
		FlxG.signals.preStateCreate.add((state) ->
		{
			checkActor(Type.getClassName(Type.getClass(state)));

			state.subStateOpened.add((sstate) ->
			{
				checkActor(Type.getClassName(Type.getClass(sstate)));
			});

			state.subStateClosed.add((_) ->
			{
				checkActor(Type.getClassName(Type.getClass(FlxG.state)));
			});
		});
	}

	private static function checkActor(resState:String)
	{
		if (uiStates.contains(resState))
			actor = UI;
		else
			actor = NOTE;

		if (noteStates.contains(resState))
			actor = NOTE;
		else
			actor = UI;
	}

	// Used for each Input Method to automatically dispatch events without too much fuss

	@:noCompletion
	public static function dispatchPressed(action:ActionType)
	{
		// Avoid firing if the Controls object from the state is null or if the actor is none
		if ((FlxG.state.controls == null && (!FlxG.state.active || !FlxG.state.persistentUpdate)) || (actor == NONE))
			return;

		Reflect.setField(Reflect.field(FlxG.state.controls, action), "state", ActionState.PRESSED);

		switch (actor)
		{
			case UI:
				if (cast(action, String).indexOf("UI_") > -1 || action == CONFIRM || action == BACK || action == RESET)
					onActionPressed.dispatch(action);

			case NOTE:
				if (cast(action, String).indexOf("NOTE_") > -1 || action == RESET || action == PAUSE)
					onActionPressed.dispatch(action);

			// easy enough lol
			case NONE:
				return;
		}
	}

	@:noCompletion
	public static function dispatchReleased(action:ActionType)
	{
		// Avoid firing if the Controls object from the state is null or if the actor is none
		if ((FlxG.state.controls == null && (!FlxG.state.active || !FlxG.state.persistentUpdate)) || (actor == NONE))
			return;

		Reflect.setField(Reflect.field(FlxG.state.controls, action), "state", ActionState.RELEASED);

		switch (actor)
		{
			case UI:
				if (cast(action, String).indexOf("UI_") > -1 || action == CONFIRM || action == BACK || action == RESET)
					onActionReleased.dispatch(action);

			case NOTE:
				if (cast(action, String).indexOf("NOTE_") > -1 || action == RESET || action == PAUSE)
					onActionReleased.dispatch(action);

			// jus return nothin
			case NONE:
				return;
		}
	}
}

// Action Class, only made for Reflection

@:publicFields
class Action
{
	var name:ActionType;
	var state:ActionState = RELEASED;

	public function new(name:ActionType)
	{
		this.name = name;
	}
}
