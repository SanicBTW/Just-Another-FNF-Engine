package flixel;

import backend.input.Controls;
import backend.scripting.*;
import base.sprites.TouchControls;
import flixel.addons.ui.FlxVirtualPad.FlxActionMode;
import flixel.addons.ui.FlxVirtualPad.FlxDPadMode;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.Rest;

/*
	Sanco here, I decided to add important stuff to the FlxState instead of doing 2 classes that extend each other soo
	Currently has: 
	- Modding API
	- Controls API
	- Preloading assets (Pending)
	- A Sandboxed Paths object that can only access specified folder (new IsolatedPaths('assets/funkin')) will only have access to that directory (Pending)
	- Music timings, once I find a way to fix delay (Implemented on MusicBeatState, pending)
 */
/**
 * This is the basic game "state" object - e.g. in a simple game you might have a menu state and a play state.
 * It is for all intents and purpose a fancy `FlxGroup`. And really, it's not even that fancy.
 */
@:keepSub // workaround for HaxeFoundation/haxe#3749
class FlxState extends FlxGroup implements IModuleAPI implements IControlsAPI implements ITouchAPI
{
	/**
	 * Determines whether or not this state is updated even when it is not the active state.
	 * For example, if you have your game state first, and then you push a menu state on top of it,
	 * if this is set to `true`, the game state would continue to update in the background.
	 * By default this is `false`, so background states will be "paused" when they are not active.
	 */
	public var persistentUpdate:Bool = false;

	/**
	 * Determines whether or not this state is updated even when it is not the active state.
	 * For example, if you have your game state first, and then you push a menu state on top of it,
	 * if this is set to `true`, the game state would continue to be drawn behind the pause state.
	 * By default this is `true`, so background states will continue to be drawn behind the current state.
	 *
	 * If background states are not `visible` when you have a different state on top,
	 * you should set this to `false` for improved performance.
	 */
	public var persistentDraw:Bool = true;

	/**
	 * If substates get destroyed when they are closed, setting this to
	 * `false` might reduce state creation time, at greater memory cost.
	 */
	public var destroySubStates:Bool = true;

	/**
	 * The natural background color the cameras default to. In `AARRGGBB` format.
	 */
	public var bgColor(get, set):FlxColor;

	/**
	 * Current substate. Substates also can be nested.
	 */
	public var subState(default, null):FlxSubState;

	/**
	 * If a state change was requested, the new state object is stored here until we switch to it.
	 */
	@:noCompletion
	private var _requestedSubState:FlxSubState;

	/**
	 * Whether to reset the substate (when it changes, or when it's closed).
	 */
	@:noCompletion
	private var _requestSubStateReset:Bool = false;

	/**
	 * A `FlxSignal` that dispatches when a sub state is opened from this state.
	 * @since 4.9.0
	 */
	public var subStateOpened(get, never):FlxTypedSignal<FlxSubState->Void>;

	/**
	 * A `FlxSignal` that dispatches when a sub state is closed from this state.
	 * @since 4.9.0
	 */
	public var subStateClosed(get, never):FlxTypedSignal<FlxSubState->Void>;

	/**
	 * Internal variables for lazily creating `subStateOpened` and `subStateClosed` signals when needed.
	 */
	@:noCompletion
	private var _subStateOpened:FlxTypedSignal<FlxSubState->Void>;

	@:noCompletion
	private var _subStateClosed:FlxTypedSignal<FlxSubState->Void>;

	/**
	 * How fast or slow time should pass in the state; default is `1.0`.
	 * This is independant per state.
	 */
	public var timeScale:Float = 1;

	// Engine Variables, exposed globally across FlxStates

	/**
	 * Holds all the current loaded modules
	 */
	private var modules:Array<ForeverModule> = [];

	/**
	 * Object that contains Game Input
	 */
	public var controls:Controls = new Controls();

	/**
	 * Sprite that contains Touchscreen Game Input
	 */
	public var touchControls:TouchControls;

	/**
	 * This function is called after the game engine successfully switches states.
	 * Override this function, NOT the constructor, to initialize or set up your game state.
	 * We do NOT recommend initializing any flixel objects or utilizing flixel features in
	 * the constructor, unless you want some crazy unpredictable things to happen!
	 */
	public function create():Void
	{
		Controls.onActionPressed.add(onActionPressed);
		Controls.onActionReleased.add(onActionReleased);
	}

	override public function draw():Void
	{
		if (persistentDraw || subState == null)
			super.draw();

		if (subState != null)
			subState.draw();
	}

	public function openSubState(SubState:FlxSubState):Void
	{
		_requestSubStateReset = true;
		_requestedSubState = SubState;
	}

	/**
	 * Closes the substate of this state, if one exists.
	 */
	public function closeSubState():Void
	{
		_requestSubStateReset = true;
	}

	/**
	 * Load substate for this state
	 */
	public function resetSubState():Void
	{
		// Close the old state (if there is an old state)
		if (subState != null)
		{
			if (subState.closeCallback != null)
				subState.closeCallback();
			if (_subStateClosed != null)
				_subStateClosed.dispatch(subState);

			if (destroySubStates)
				subState.destroy();
		}

		// Assign the requested state (or set it to null)
		subState = _requestedSubState;
		_requestedSubState = null;

		if (subState != null)
		{
			// Reset the input so things like "justPressed" won't interfere
			if (!persistentUpdate)
				FlxG.inputs.onStateSwitch();

			subState._parentState = this;

			if (!subState._created)
			{
				subState._created = true;
				subState.create();
			}
			if (subState.openCallback != null)
				subState.openCallback();
			if (_subStateOpened != null)
				_subStateOpened.dispatch(subState);
		}
	}

	override public function destroy():Void
	{
		Controls.onActionPressed.remove(onActionPressed);
		Controls.onActionReleased.remove(onActionReleased);
		controls = null;

		if (touchControls != null)
		{
			touchControls = FlxDestroyUtil.destroy(touchControls);
			touchControls = null;
		}

		FlxDestroyUtil.destroy(_subStateOpened);
		FlxDestroyUtil.destroy(_subStateClosed);

		if (subState != null)
		{
			subState.destroy();
			subState = null;
		}
		super.destroy();
	}

	/**
	 * Called from `FlxG.switchState()`. If `false` is returned, the state
	 * switch is cancelled - the default implementation returns `true`.
	 *
	 * Useful for customizing state switches, e.g. for transition effects.
	 */
	public function switchTo(nextState:FlxState):Bool
	{
		return true;
	}

	/**
	 * This method is called after the game loses focus.
	 * Can be useful for third party libraries, such as tweening engines.
	 */
	public function onFocusLost():Void {}

	/**
	 * This method is called after the game receives focus.
	 * Can be useful for third party libraries, such as tweening engines.
	 */
	public function onFocus():Void {}

	/**
	 * This function is called whenever the window size has been changed.
	 *
	 * @param   Width    The new window width
	 * @param   Height   The new window Height
	 */
	public function onResize(Width:Int, Height:Int):Void {}

	/// ModuleAPI Implementation

	/**
	 * Used to call a function that is inside a module. 
	 * 
	 * It loops through all of the loaded modules, only executing the active ones.
	 * 
	 * @param 	func	 The function to execute
	 * @param 	args	 Arguments to pass to the function on execution
	 */
	public function callOnModules(func:String, args:Rest<Dynamic>)
	{
		try
		{
			for (module in modules)
			{
				if (module.active && module.exists(func))
					Reflect.callMethod(module.interp.variables, module.get(func), args.toArray()); // WTF IT WORKS LMFAOOO
			}
		}
		catch (ex)
		{
			trace('Failed to execute $func on modules ($ex)');
		}
	}

	/**
	 * Used to set a variable inside the loaded modules.
	 *
	 * It loops through all of the loaded modules, only modifying the active ones.
	 * 
	 * @param 	variable The target variable
	 * @param 	arg		 The new value of `variable`
	 */
	public function setOnModules(variable:String, arg:Dynamic)
	{
		try
		{
			for (module in modules)
			{
				if (module.active)
					module.set(variable, arg);
			}
		}
		catch (ex)
		{
			trace('Failed to set $variable on modules ($ex)');
		}
	}

	/// ControlsAPI

	/**
	 * This method is called when the Controls receive a KeyPress on the Window
	 */
	public function onActionPressed(action:ActionType) {}

	/**
	 * This method is called when the Controls receive a KeyReleased on the Window
	 */
	public function onActionReleased(action:ActionType) {}

	/// TouchAPI
	// Starting flag to set the usage of the touch controls on HTML5
	#if html5 public static var enableTouch:Bool = false; #end

	/**
	 * Call this method to add touch controls to the current state, always call this function after super.create
	 * 
	 * This function only takes effect on Mobile targets and HTML5 through a starting argument
	 */
	public function addTouchControls(mode:ControlsMode, ?DPad:FlxDPadMode, ?Action:FlxActionMode)
	{
		#if (mobile || html5)
		#if html5
		if (!enableTouch)
			return;
		#end

		touchControls = new TouchControls(mode, DPad, Action);

		var camControls = new flixel.FlxCamera();
		FlxG.cameras.add(camControls, false);
		camControls.bgColor.alpha = 0;

		touchControls.cameras = [camControls];
		touchControls.visible = true;
		add(touchControls);
		#end
	}

	/**
	 * Call this method to remove touch controls from the current state
	 * 
	 * This function only takes effect on Mobile targets and HTML5 through a starting argument
	 */
	public function removeTouchControls()
	{
		#if (mobile || html5)
		#if html5
		if (!enableTouch)
			return;
		#end
		if (touchControls != null)
			remove(touchControls);
		#end
	}

	@:allow(flixel.FlxGame)
	private function tryUpdate(elapsed:Float):Void
	{
		if (persistentUpdate || subState == null)
			update(elapsed * timeScale);

		if (_requestSubStateReset)
		{
			_requestSubStateReset = false;
			resetSubState();
		}
		if (subState != null)
		{
			subState.tryUpdate(elapsed * timeScale);
		}
	}

	@:noCompletion
	private function get_bgColor():FlxColor
	{
		return FlxG.cameras.bgColor;
	}

	@:noCompletion
	private function set_bgColor(Value:FlxColor):FlxColor
	{
		return FlxG.cameras.bgColor = Value;
	}

	@:noCompletion
	private function get_subStateOpened():FlxTypedSignal<FlxSubState->Void>
	{
		if (_subStateOpened == null)
			_subStateOpened = new FlxTypedSignal<FlxSubState->Void>();

		return _subStateOpened;
	}

	@:noCompletion
	private function get_subStateClosed():FlxTypedSignal<FlxSubState->Void>
	{
		if (_subStateClosed == null)
			_subStateClosed = new FlxTypedSignal<FlxSubState->Void>();

		return _subStateClosed;
	}
}

// More interfaces will come soon like, languages, active networking, etc
// Input Shit

interface IControlsAPI
{
	// Object that contains game input, as well as having a static exposure for single key input
	public var controls:Controls;

	public function onActionPressed(action:ActionType):Void;
	public function onActionReleased(action:ActionType):Void;
}

// Totally not a ripoff FunkinLua from Psych Engine (its 3 am leave me alone)

interface IModuleAPI
{
	// Array that contains all of the loaded modules (automatically pushed through ScriptHandler.loadModule)
	private var modules:Array<ForeverModule>;

	// Will only execute the active modules
	public function callOnModules(event:String, args:Rest<Dynamic>):Void;
	public function setOnModules(variable:String, arg:Dynamic):Void;
}

// More input shit but for touch screens
interface ITouchAPI
{
	// Sprite that contains the game input for touch screens, DPAD or Hitbox
	public var touchControls:TouchControls;

	public function addTouchControls(mode:ControlsMode, ?DPAD:FlxDPadMode, ?Action:FlxActionMode):Void;
	public function removeTouchControls():Void;
}
