package base.ui;

import flixel.FlxSprite;

// https://github.com/SanicBTW/Forever-Engine-Archive/blob/rewrite/source/base/ForeverDependencies.hx
// Should look into this soon

class DepthSprite extends FlxSprite
{
	public var zDepth:Float = 0;

	public function new(X:Float = 0, Y:Float = 0)
	{
		super(X, Y);
	}

	public static inline function depthSorting<T:DepthSprite>(Order:Int, Obj1:T, Obj2:T)
	{
		if (Obj1.zDepth > Obj2.zDepth)
			return -Order;
		return Order;
	}
}

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
		animation.play(AnimName, Force, Reversed, Frame);

		if (animOffsets.exists(AnimName))
			offset.set(animOffsets[AnimName][0], animOffsets[AnimName][1]);
		else
			offset.set(0, 0);
	}
}
