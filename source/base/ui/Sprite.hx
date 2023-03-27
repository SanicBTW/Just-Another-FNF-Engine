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

class AttachedSprite extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public function new(?file:String = null)
	{
		super();
		if (file != null)
			loadGraphic(Paths.image(file));
		antialiasing = SaveData.antialiasing;
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if (copyAngle)
				angle = sprTracker.angle + angleAdd;

			if (copyAlpha)
				alpha = sprTracker.alpha * alphaMult;

			if (copyVisible)
				visible = sprTracker.visible;
		}
	}
}
