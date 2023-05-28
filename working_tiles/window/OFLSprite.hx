package window;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.Font;
import openfl.utils.Assets;

// Custom sprites and shit implementation
// Most of the code comes from the old Tray code
class OFLSprite extends Sprite
{
	// Update only when its active
	public var active:Bool = true;

	// Look for another way to pass raw delta time (openfl)
	public var rawElapsed:Float = 0;

	public function new()
	{
		super();

		create();
	}

	// Fired after setting up some essentials on constructor

	private function create() {}

	// Triggers the update function passing elapsed-a-like from FlxG
	// Instead of getting it from a getter and improving update calls)?

	@:noCompletion
	private override function __enterFrame(deltaTime:Float):Void
	{
		if (!active || !visible)
			return;

		rawElapsed = deltaTime;
		update(deltaTime / 1000);
	}

	private function update(elapsed:Float) {}

	public function destroy() {}

	public function screenCenter()
	{
		x = (0.5 * (Lib.current.stage.stageWidth - width));
	}

	// Long ass function arguments and stupid function name
	private function drawRound(X:Float = 0, Y:Float = 0, Width:Float = 50, Height:Float = 50, CornerRadius:Array<Float>, Color:FlxColor = FlxColor.WHITE,
			Alpha:Float = 1):Shape
	{
		var shape:Shape = new Shape();

		shape.graphics.beginFill(Color, Alpha);

		if (CornerRadius.length < 3)
			shape.graphics.drawRoundRect(X, Y, Width, Height, CornerRadius[0]);
		else
			shape.graphics.drawRoundRectComplex(X, Y, Width, Height, CornerRadius[0], CornerRadius[1], CornerRadius[2], CornerRadius[3]);

		shape.graphics.endFill();

		return shape;
	}

	private inline function getFont(font:String):Font
		return Assets.getFont(Paths.font(font));

	private inline function boundTo(value:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, value));

	// funky stuff
	private function lerpTrack<T:DisplayObject>(sprite:T, property:String, track:Float, ratio:Float)
	{
		var field = Reflect.getProperty(sprite, property);
		var lerp:Float = FlxMath.lerp(track, field, ratio);
		Reflect.setProperty(sprite, property, lerp);
	}
}
