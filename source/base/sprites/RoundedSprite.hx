package base.sprites;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import window.components.RoundedSprite as OpenFLRoundedSprite;

// should just name these 2 different ig idk
class RoundedSprite extends FlxSprite
{
	public var lerp:Null<Float> = null;

	private var _sprite:OpenFLRoundedSprite;

	@:noCompletion
	override private function set_alpha(Alpha:Float):Float
	{
		super.set_alpha(Alpha);
		_sprite.alpha = Alpha;
		return Alpha;
	}

	// return the sizes from the real sizes vector, just in case theres an error in the middleware

	@:noCompletion
	override private function get_width():Float
		return (_sprite != null) ? _sprite.RealSizes.x : width;

	@:noCompletion
	override private function set_width(Width:Float):Float
	{
		return (_sprite != null) ? {_sprite.setSize(Width, height, lerp); return _sprite.RealSizes.x;} : width = Width;
	}

	@:noCompletion
	override private function get_height():Float
		return (_sprite != null) ? _sprite.RealSizes.y : height;

	@:noCompletion
	override private function set_height(Height:Float):Float
	{
		return (_sprite != null) ? {_sprite.setSize(width, Height, lerp); return _sprite.RealSizes.y;} : height = Height;
	}

	public function new(X:Float, Y:Float, Width:Int, Height:Int, CornerRadius:Array<Float>, Color:FlxColor, Alpha:Float = 1)
	{
		super(X, Y);

		makeGraphic(Width, Height, FlxColor.TRANSPARENT, true);
		_sprite = new OpenFLRoundedSprite(0, 0, Width, Height, CornerRadius, Color);
		this.alpha = Alpha;
	}

	override public function draw()
	{
		if (_sprite == null)
			return;

		pixels.draw(_sprite);

		super.draw();
	}
}
