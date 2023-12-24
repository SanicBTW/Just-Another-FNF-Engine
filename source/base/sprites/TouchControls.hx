package base.sprites;

import flixel.addons.ui.FlxHitbox;
import flixel.addons.ui.FlxVirtualPad;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxDestroyUtil;

enum ControlsMode
{
	DPAD;
	HITBOX;
	NONE;
}

class TouchControls extends FlxSpriteGroup
{
	public var virtualPad:FlxVirtualPad;
	public var hitbox:FlxHitbox;

	public function new(mode:ControlsMode, ?DPad:FlxDPadMode, ?Action:FlxActionMode)
	{
		super();

		switch (mode)
		{
			case DPAD:
				virtualPad = new FlxVirtualPad(DPad, Action);
				add(virtualPad);
			case HITBOX:
				hitbox = new FlxHitbox();
				add(hitbox);
			case NONE:
		}
	}

	override public function destroy():Void
	{
		super.destroy();

		if (virtualPad != null)
		{
			virtualPad = FlxDestroyUtil.destroy(virtualPad);
			virtualPad = null;
		}

		if (hitbox != null)
		{
			hitbox = FlxDestroyUtil.destroy(hitbox);
			hitbox = null;
		}
	}
}
