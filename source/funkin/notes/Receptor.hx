package funkin.notes;

import base.SaveData;
import flixel.FlxSprite;

class Receptor extends FlxSprite
{
	public var arrowType:Int = 0;
	public var initialX:Int;
	public var initialY:Int;

	public var setAlpha:Float = 0.8;
	public var resetAnim:Float = 0;

	public function new(x:Float, y:Float, arrowType:Int = 0)
	{
		this.arrowType = arrowType;
		super(x, y);

		// my dumb ass was setting the frames before super :skull:
		frames = Paths.getSparrowAtlas('NOTE_assets');
		loadAnims();
		updateHitbox();
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}

		if (animation.curAnim.name == "confirm")
			centerOrigin();

		super.update(elapsed);
	}

	public function playAnim(AnimName:String, Force:Bool = false)
	{
		if (AnimName == "confirm")
		{
			alpha = 1;
			centerOrigin();
		}
		else
			alpha = setAlpha;

		animation.play(AnimName, Force);
		centerOffsets();
		centerOrigin();
	}

	private function loadAnims()
	{
		var stringSect:String = getArrowFromNum(arrowType);
		animation.addByPrefix('static', 'arrow${stringSect.toUpperCase()}');
		animation.addByPrefix('pressed', '$stringSect press', 24, false);
		animation.addByPrefix('confirm', '$stringSect confirm', 24, false);
		setGraphicSize(Std.int(width * 0.7));
		antialiasing = SaveData.antialiasing;
	}

	public static function getArrowFromNum(num:Int)
	{
		var stringSex:String = "";
		switch (num)
		{
			case 0:
				stringSex = "left";
			case 1:
				stringSex = "down";
			case 2:
				stringSex = "up";
			case 3:
				stringSex = "right";
		}
		return stringSex;
	}

	public static function getColorFromNum(num:Int)
	{
		var stringSex:String = "";
		switch (num)
		{
			case 0:
				stringSex = "purple";
			case 1:
				stringSex = "blue";
			case 2:
				stringSex = "green";
			case 3:
				stringSex = "red";
		}
		return stringSex;
	}
}
