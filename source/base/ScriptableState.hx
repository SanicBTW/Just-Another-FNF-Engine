package base;

import base.Controls;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUISubState;

// From FNF-Forever-Engine (My fork)
class ScriptableState extends FlxUIState
{
	override function create()
	{
		super.create();
		Controls.onActionPressed.add(onActionPressed);
		Controls.onActionReleased.add(onActionReleased);
	}

	override function destroy()
	{
		Controls.onActionPressed.remove(onActionPressed);
		Controls.onActionReleased.remove(onActionReleased);
		super.destroy();
	}

	function onActionPressed(action:String)
	{
		trace("Pressed: " + action);
	}

	function onActionReleased(action:String)
	{
		trace("Released: " + action);
	}
}

class ScriptableSubState extends FlxUISubState
{
	override function create()
	{
		super.create();
		Controls.onActionPressed.add(onActionPressed);
		Controls.onActionReleased.add(onActionReleased);
	}

	override function destroy()
	{
		Controls.onActionPressed.remove(onActionPressed);
		Controls.onActionReleased.remove(onActionReleased);
		super.destroy();
	}

	function onActionPressed(action:String) {}

	function onActionReleased(action:String) {}
}
