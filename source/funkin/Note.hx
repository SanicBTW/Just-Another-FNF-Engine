package funkin;

import base.Conductor;
import base.SaveData;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import states.PlayTest;

class Note extends FlxSprite
{
	public static var swagWidth:Float = 160 * 0.7;

	public var dataShit:Map<Int, Array<String>> = [
		0 => ["purple", "left"],
		1 => ["blue", "down"],
		2 => ["green", "up"],
		3 => ["red", "right"]
	];

	public var stepTime:Float;
	public var noteData:Int;
	public var isSustain:Bool = false;
	public var prevNote:Note;
	public var tooLate:Bool = false;
	public var canBeHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var sustainLength:Float = 0;
	public var noteYOff:Int = 0;
	public var mustPress:Bool = false;

	public var parent:Note = null;
	public var children:Array<Note> = [];

	public function new(stepTime:Float, noteData:Int, ?prevNote:Note, ?isSustain:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.isSustain = isSustain;
		this.noteData = noteData;
		this.stepTime = stepTime;

		y -= 2000;

		if (noteData > -1)
		{
			frames = Paths.getSparrowAtlas('NOTE_assets');
			for (i in 0...4)
			{
				animation.addByPrefix('${dataShit.get(i)[0]}Scroll', '${dataShit.get(i)[0]}0');
				animation.addByPrefix('${dataShit.get(i)[0]}holdend', '${dataShit.get(i)[0]} hold end');
				animation.addByPrefix('${dataShit.get(i)[0]}hold', '${dataShit.get(i)[0]} hold piece');
			}
			animation.addByPrefix('purpleholdend', 'pruple end hold');

			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();

			antialiasing = SaveData.antialiasing;

			x += swagWidth * noteData;
			if (!isSustain)
				animation.play('${dataShit.get(noteData)[0]}Scroll');
		}

		var stepHeight = (0.45 * Conductor.stepCrochet * FlxMath.roundDecimal(PlayTest.SONG.speed, 2));

		if (isSustain && prevNote != null)
		{
			alpha = 0.6;
			x += width / 2;

			animation.play('${dataShit.get(noteData)[0]}holdend');
			updateHitbox();

			x -= width / 2;

			if (prevNote.isSustain)
			{
				prevNote.animation.play('${dataShit.get(noteData)[0]}hold');
				prevNote.updateHitbox();

				prevNote.scale.y *= (stepHeight + 1) / prevNote.height;
				prevNote.updateHitbox();
				prevNote.noteYOff = Math.round(-prevNote.offset.y);

				noteYOff = Math.round(-offset.y);
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			if (isSustain)
			{
				if (stepTime - Conductor.songPosition <= ((166 * Conductor.timeScale) * 0.5)
					&& stepTime - Conductor.songPosition >= ((-166 * Conductor.timeScale)))
					canBeHit = true;
				else
					canBeHit = false;
			}
			else
			{
				if (stepTime - Conductor.songPosition <= ((166 * Conductor.timeScale))
					&& stepTime - Conductor.songPosition >= ((-166 * Conductor.timeScale)))
					canBeHit = true;
				else
					canBeHit = false;
			}

			if (stepTime - Conductor.songPosition < -166 && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (stepTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate && !wasGoodHit)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}
