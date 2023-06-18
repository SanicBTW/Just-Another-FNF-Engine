package quaver.notes;

import flixel.FlxSprite;
import states.ScrollTest;

class Receptor extends FlxSprite
{
	public var noteData:Int = 0;

	public function new(X:Float, Y:Float, noteData:Int = 0)
	{
		this.noteData = noteData;
		super(X, Y);

		frames = ScrollTest.Paths.getSparrowAtlas('NOTE_assets');
		loadAnims();
		updateHitbox();
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim != null && animation.curAnim.name == "confirm")
			centerOrigin();

		super.update(elapsed);
	}

	public function playAnim(AnimName:String, Force:Bool = false)
	{
		if (AnimName == "confirm")
			centerOrigin();

		animation.play(AnimName, Force);
		centerOffsets();
		centerOrigin();
	}

	private function loadAnims()
	{
		var color:String = getArrowFromNum(noteData);

		animation.addByPrefix('static', 'arrow${color.toUpperCase()}');
		animation.addByPrefix('pressed', '$color press', 24, false);
		animation.addByPrefix('confirm', '$color confirm', 24, false);

		setGraphicSize(Std.int(width * 0.7));
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
