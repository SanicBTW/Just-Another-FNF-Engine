package base.ui;

import flixel.FlxSprite;

// https://github.com/SanicBTW/Forever-Engine-Archive/blob/rewrite/source/base/ForeverDependencies.hx
class Sprite extends FlxSprite
{
	public var offsets:Map<String, Array<Dynamic>>;
	public var zDepth:Float = 0;

	public function new(?x:Float, ?y:Float)
	{
		super(x, y);
		offsets = new Map();
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
		offsets[name] = [x, y];

	public function resizeOffsets(?newScale:Float)
	{
		if (newScale == null)
			newScale = scale.x;
		for (i in offsets.keys())
			offsets[i] = [offsets[i][0] * newScale, offsets[i][1] * newScale];
	}

	public function playAnim(AnimName:String, ?Force:Bool = false, ?Reversed:Bool = false, ?Frame:Int = 0)
	{
		animation.play(AnimName, Force, Reversed, Frame);
		centerOffsets();
		centerOrigin();

		if (offsets.exists(AnimName))
			offset.set(offsets[AnimName][0], offsets[AnimName][0]);
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
