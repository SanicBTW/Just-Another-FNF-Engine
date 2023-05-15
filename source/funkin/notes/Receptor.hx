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

	// Holds the order of receptors (bruh)
	private static var order:IntMap<Array<Int>> = [
		1 => [0],
		2 => [0, 1],
		3 => [0, 1, 2],
		4 => [0, 1, 2, 3],
		5 => [0, 1, 2, 3, 4],
		6 => [0, 1, 2, 3, 4, 5],
		7 => [0, 1, 2, 3, 4, 5, 6],
		8 => [0, 1, 2, 3, 4, 5, 6, 7],
		9 => [0, 1, 2, 3, 4, 5, 6, 7, 8]
	];

	// Holds the order of receptor directions
	private static var directions:IntMap<Array<String>> = [
		1 => ["space"],
		2 => ["left", "right"],
		3 => ["left", "space", "right"],
		4 => ["left", "down", "up", "right"],
		5 => ["left", "down", "space", "up", "right"],
		6 => ["left", "down", "right", "left", 'up', 'right'],
		7 => ["left", "down", "right", "space", "left", "up", "right"],
		8 => ["left", "down", "up", "right", "left", "down", "up", "right"],
		9 => ["left", "down", "up", "right", "space", "left", "down", "up", "right"]
	];

	// Holds the order of receptor actions (for input)
	private static var actions:IntMap<Array<String>> = [
		1 => ["special"],
		2 => ["left", "right"],
		3 => ["left", "special", "right"],
		4 => ["left", "down", "up", "right"],
		5 => ["left", "down", "special", "up", "right"],
		6 => ["left1", "down", "right1", "left2", 'up', 'right2'],
		7 => ["left1", "down", "right1", "special", "left2", "up", "right2"],
		8 => ["left1", "down1", "up1", "right1", "left2", "down2", "up2", "right2"],
		9 => ["left1", "down1", "up1", "right1", "special", "left2", "down2", "up2", "right2"]
	];

	// Holds the order of receptor colors
	private static var colors:IntMap<Array<String>> = [
		1 => ["white"],
		2 => ["left", "right"],
		3 => ["left", "white", "right"],
		4 => ["left", "down", "up", "right"],
		5 => ["left", "down", "white", "up", "right"],
		6 => ["left", "down", "right", "yellow", 'up', 'dark'],
		7 => ["left", "down", "right", "white", "yellow", 'up', 'dark'],
		8 => ["left", "down", "up", "right", "yellow", 'violet', 'black', 'dark'],
		9 => ["left", "down", "up", "right", "white", "yellow", 'violet', 'black', 'dark']
	];

	// Holds the order of note colors
	private static var noteColors:IntMap<Array<String>> = [
		1 => ["white"],
		2 => ["purple", "red"],
		3 => ["purple", "white", "red"],
		4 => ["purple", "blue", "green", "red"],
		5 => ["purple", "blue", "white", "green", "red"],
		6 => ["purple", "blue", "red", "yellow", 'green', 'dark'],
		7 => ["purple", "blue", "red", "white", "yellow", 'green', 'dark'],
		8 => ["purple", "blue", "green", "red", "yellow", 'violet', 'black', 'dark'],
		9 => ["purple", "blue", "green", "red", "white", "yellow", 'violet', 'black', 'dark']
	];

	public function new(X:Float, Y:Float, noteData:Int)
	{
		this.noteData = noteData;
		this.action = getActionFromNum(noteData);
		super(X, Y);

		frames = Paths.getSparrowAtlas('NOTE_assets');
		loadAnimations();
		updateHitbox();
		antialiasing = true;

		scrollFactor.y = 0;
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
		var color:String = getColorFromNum(noteData);

		animation.addByPrefix('static', 'arrow${direction.toUpperCase()}');
		animation.addByPrefix('pressed', '$color press', 30, false);
		animation.addByPrefix('confirm', '$color confirm', 30, false);
		setGraphicSize(Std.int(width * 0.7));
	}

	public static function getArrowFromNum(num:Int):String
	{
		var realNum:Int = order.get(Conductor.SONG.mania).indexOf(num);

		// Just in case
		if (realNum == -1)
			throw 'Couldn\'t find $num on order';

		var dirArray:Array<String> = directions.get(Conductor.SONG.mania);
		return dirArray[realNum];
	}

	public static function getColorFromNum(num:Int):String
	{
		var realNum:Int = order.get(Conductor.SONG.mania).indexOf(num);

		// Just in case
		if (realNum == -1)
			throw 'Couldn\'t find $num on order';

		var colorArray:Array<String> = colors.get(Conductor.SONG.mania);
		return colorArray[realNum];
	}

	public static function getNoteColorFromNum(num:Int):String
	{
		var realNum:Int = order.get(Conductor.SONG.mania).indexOf(num);

		// Just in case
		if (realNum == -1)
			throw 'Couldn\'t find $num on order';

		var colorArray:Array<String> = noteColors.get(Conductor.SONG.mania);
		return colorArray[realNum];
	}

	public static function getActionFromNum(num:Int):String
	{
		var realNum:Int = order.get(Conductor.SONG.mania).indexOf(num);

		// Just in case
		if (realNum == -1)
			throw 'Couldn\'t find $num on order';

		var actionArray:Array<String> = actions.get(Conductor.SONG.mania);
		return actionArray[realNum];
	}
}
