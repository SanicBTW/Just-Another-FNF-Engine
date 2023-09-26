package engine.sprites;

import flixel.FlxSprite;

// https://github.com/SanicBTW/Forever-Engine-Archive/blob/rewrite/source/base/ForeverDependencies.hx
class DepthSprite extends FlxSprite
{
	public var z:Float = 0;

	public function new(X:Float = 0, Y:Float = 0)
	{
		super(X, Y);
	}

	public static inline function depthSorting<T:DepthSprite>(Order:Int, Obj1:T, Obj2:T)
	{
		if (Obj1.z > Obj2.z)
			return -Order;
		return Order;
	}
}
