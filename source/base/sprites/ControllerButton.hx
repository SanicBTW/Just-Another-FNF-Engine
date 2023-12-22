package base.sprites;

import backend.input.Controller;
import flixel.FlxSprite;
import flixel.graphics.atlas.FlxAtlas;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;

// Hardcoded to only support XBOX and PS4 graphics
// Manage hitboxes
// Art made by Slac, thanks a lot!
class ControllerButton extends FlxSpriteGroup
{
	private var buttons:FlxSprite;
	private var shoulders:FlxSprite;
	private var dpad:FlxSprite;

	override public function new(X:Float = 0, Y:Float = 0)
	{
		super(X, Y);

		// Buttons - did some cool ass math to get the correct button cuz the order is like a b x y
		buttons = new FlxSprite().loadGraphic(Paths.image("ui/controller/buttons"), true, 82, 80);
		buttons.visible = false;

		var max:Int = 4;
		for (i in 0...max)
		{
			var sprIndex:Int = (max - i) % max;

			buttons.animation.add('ps4-$sprIndex', [i]);
			buttons.animation.add('xbox-$sprIndex', [4 + i]);
		}

		// Shoulders (L1 R1 / LB RB)
		shoulders = new FlxSprite().loadGraphic(Paths.image("ui/controller/shoulders"), true, 123, 50);

		// no loop cuz im dumb

		shoulders.animation.add("ps4-9", [0]);
		shoulders.animation.add("xbox-9", [2]);

		shoulders.animation.add("ps4-10", [1]);
		shoulders.animation.add("xbox-10", [3]);

		shoulders.visible = false;

		// DPAD - Directional pad, design is forced to ps4 cuz we cool, this one is a little bit tricky since its separated into different graphics
		dpad = new FlxSprite();
		setDPadFrames();
		dpad.visible = false;

		add(buttons);
		add(shoulders);
		add(dpad);
	}

	private function setDPadFrames()
	{
		var atlas:FlxAtlas = new FlxAtlas("dpad", FlxPoint.weak(0, 0), FlxPoint.weak(0, 0));

		var directions:Array<String> = ["Up", "Down", "Left", "Right"];

		for (dir in directions)
		{
			atlas.addNode(Paths.image('ui/controller/dpad$dir').bitmap, 'dpad_${directions.indexOf(dir)}');
		}

		dpad.frames = atlas.getAtlasFrames();

		var i:Int = 11;
		for (dir in directions)
		{
			dpad.animation.addByPrefix('ps4-$i', 'dpad_${directions.indexOf(dir)}');
			dpad.animation.addByPrefix('xbox-$i', 'dpad_${directions.indexOf(dir)}');
			i++;
		}
	}

	override public function update(elapsed:Float)
	{
		if (Controller.buttonsPressed.length > 0)
		{
			var button = Controller.rawIntToButton(Controller.buttonsPressed[0]);
			var animToPlay:String = '${Controller.type}-${Controller.buttonsPressed[0]}';
			switch (button)
			{
				// I told Slac to not draw the rest of the buttons because they were unchangeable and theres no reason to draw non usable assets yknow
				default:
					return;

				case A | B | X | Y:
					buttons.visible = true;
					shoulders.visible = false;
					dpad.visible = false;
					buttons.animation.play(animToPlay);

				case LEFT_SHOULDER | RIGHT_SHOULDER:
					buttons.visible = false;
					shoulders.visible = true;
					dpad.visible = false;
					shoulders.animation.play(animToPlay);

				case DPAD_UP | DPAD_DOWN | DPAD_LEFT | DPAD_RIGHT:
					buttons.visible = false;
					shoulders.visible = false;
					dpad.visible = true;
					dpad.animation.play(animToPlay);
			}
		}

		super.update(elapsed);
	}
}
