package window;

import flixel.math.FlxMath;
import openfl.Lib;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.text.Font;
import openfl.utils.Assets;

// Custom sprites and shit implementation
// Extended sprite (ExSprite lol)
class ExSprite<T> extends Sprite
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

	private inline function getFont(font:String):Font
		return Assets.getFont(backend.Cache.getFont(font));

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
