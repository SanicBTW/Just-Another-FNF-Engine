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
		switch (action)
		{
			case "vol_up":
				SoundManager.globalVolume += 0.1;
			case "vol_down":
				SoundManager.globalVolume -= 0.1;
			case "mute":
				SoundManager.muted = !SoundManager.muted;
		}
	}

	function onActionReleased(action:String) {}
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

	function onActionPressed(action:String)
	{
		switch (action)
		{
			case "vol_up":
				SoundManager.globalVolume += 0.1;
			case "vol_down":
				SoundManager.globalVolume -= 0.1;
			case "mute":
				SoundManager.muted = !SoundManager.muted;
		}
	}

	function onActionReleased(action:String) {}
}
