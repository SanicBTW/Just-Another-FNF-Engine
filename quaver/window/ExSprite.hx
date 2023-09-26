package window;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.DisplayObject;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.Font;
import openfl.utils.Assets;

// Custom sprites and shit implementation
// Extended sprite (ExSprite lol)
class ExSprite extends Sprite
{
	// Update only when its active
	public var active:Bool = true;

	public function new()
	{
		super();

		create();
	}

	private function create() {}

	// Triggers the update function passing elapsed-a-like from FlxG and raw elapsed from OpenFL

	@:noCompletion
	private override function __enterFrame(deltaTime:Float):Void
	{
		if (!active || !visible)
			return;

		update(deltaTime / 1000, deltaTime);
	}

	private function update(elapsed:Float, deltaTime:Float) {}

	public function destroy() {}

	public function screenCenter()
	{
		x = (0.5 * (Lib.current.stage.stageWidth - width));
		y = (0.5 * (Lib.current.stage.stageHeight - height));
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
		return Assets.getFont(backend.Cache.getFont(font));

	// funky stuff
	private function lerpTrack<T:DisplayObject>(sprite:T, property:String, track:Float, ratio:Float)
	{
		var field = Reflect.getProperty(sprite, property);
		var lerp:Float = FlxMath.lerp(track, field, ratio);
		Reflect.setProperty(sprite, property, lerp);
	}
}
