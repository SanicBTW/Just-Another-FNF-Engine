package base.ui;

import flixel.FlxSprite;

// https://github.com/SanicBTW/Forever-Engine-Archive/blob/rewrite/source/base/ForeverDependencies.hx
class Sprite extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var zDepth:Float = 0;

	public function new(?x:Float, ?y:Float)
	{
		super(x, y);
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

	public static inline function depthSorting(Order:Int, Obj1:Sprite, Obj2:Sprite)
	{
		if (Obj1.zDepth > Obj2.zDepth)
			return -Order;
		return Order;
	}
}
