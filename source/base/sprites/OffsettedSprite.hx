package base.sprites;

import flixel.FlxSprite;

// https://github.com/SanicBTW/Forever-Engine-Archive/blob/rewrite/source/base/ForeverDependencies.hx
class OffsettedSprite extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;

	public function new(X:Float = 0, Y:Float = 0)
	{
		super(X, Y);
		animOffsets = new Map();
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
		animOffsets[name] = [x, y];

	public function resizeOffsets(?newScale:Float)
	{
		if (newScale == null)
			newScale = scale.x;
		for (i in animOffsets.keys())
			animOffsets[i] = [animOffsets[i][0] * newScale, animOffsets[i][1] * newScale];
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		if (animation.getByName(AnimName) != null)
			animation.play(AnimName, Force, Reversed, Frame);

		if (animOffsets.exists(AnimName))
			offset.set(animOffsets[AnimName][0], animOffsets[AnimName][1]);
		else
			offset.set(0, 0);
	}
}
