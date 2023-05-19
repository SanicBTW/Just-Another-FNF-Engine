package funkin.notes;

import base.Conductor;
import flixel.FlxSprite;
import haxe.ds.IntMap;

// Add note scale
class Receptor extends FlxSprite
{
	public var noteData:Int = 0;

	public var initialX:Int;
	public var initialY:Int;

	public var setAlpha:Float = 0.8;

	public var holdTimer:Float = 0;
	public var direction:Float = 0;

	public var action:String = "";

	public function new(X:Float, Y:Float, noteData:Int)
	{
		this.noteData = noteData;
		super(X, Y);

		this.action = 'note_${getArrowFromNum(noteData)}';
		frames = Paths.getSparrowAtlas('NOTE_assets');
		loadAnimations();
		updateHitbox();
		antialiasing = true;
	}

	override function update(elapsed:Float)
	{
		if (holdTimer > 0)
		{
			holdTimer -= elapsed;
			if (holdTimer <= 0)
			{
				playAnim('static');
				holdTimer = 0;
			}
		}

		if (animation.curAnim != null && animation.curAnim.name == 'confirm')
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

	private function loadAnimations()
	{
		var direction:String = getArrowFromNum(noteData);

		animation.addByPrefix('static', 'arrow${direction.toUpperCase()}');
		animation.addByPrefix('pressed', '$direction press', 30, false);
		animation.addByPrefix('confirm', '$direction confirm', 30, false);
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
