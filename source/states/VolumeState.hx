package states;

import base.ScriptableState;
import base.SoundManager;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

// test state to test the volume bar design and code
class VolumeState extends ScriptableState
{
	var volumeTracker:FlxSprite;

	override function create()
	{
		volumeTracker = new FlxSprite(0, 0).makeGraphic(15, 100, FlxColor.WHITE);
		volumeTracker.screenCenter();
		add(volumeTracker);

		super.create();
	}

	override function update(elapsed:Float)
	{
		volumeTracker.scale.y = FlxMath.lerp(SoundManager.globalVolume, volumeTracker.scale.y, 0.95);

		super.update(elapsed);
	}
}
