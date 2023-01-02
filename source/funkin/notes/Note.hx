package funkin.notes;

import base.Conductor;
import base.SaveData;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import states.PlayTest;

// todo: make receptor to be used as using
class Note extends FlxSprite
{
	public static var swagWidth:Float = 160 * 0.7;

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
			loadNoteAnims(this, noteData, isSustain);
			antialiasing = SaveData.antialiasing;

			x += swagWidth * noteData;
			if (!isSustain)
				animation.play('${Receptor.getColorFromNum(noteData)}Scroll');
		}

		var stepHeight = (0.45 * Conductor.stepCrochet * FlxMath.roundDecimal(PlayTest.SONG.speed, 2));

		if (isSustain && prevNote != null)
		{
			alpha = 0.6;
			x += width / 2;

			animation.play('${Receptor.getColorFromNum(noteData)}holdend');
			updateHitbox();

			x -= width / 2;

			if (prevNote.isSustain)
			{
				prevNote.animation.play('${Receptor.getColorFromNum(noteData)}hold');
				prevNote.updateHitbox();

				prevNote.scale.y *= (stepHeight + 1) / prevNote.height;
				prevNote.updateHitbox();
				prevNote.noteYOff = Math.round(-prevNote.offset.y);

				noteYOff = Math.round(-offset.y);
			}
		}
	}

	// this shit totally doesnt comes from my 0.3.2h fork
	private function loadNoteAnims(sprite:Note, noteData:Int, isSustainNote:Bool)
	{
		sprite.animation.addByPrefix('${Receptor.getColorFromNum(noteData)}Scroll', '${Receptor.getColorFromNum(noteData)}0');

		if (isSustainNote)
		{
			sprite.animation.addByPrefix('purpleholdend', 'pruple end hold'); // lmao
			sprite.animation.addByPrefix('${Receptor.getColorFromNum(noteData)}holdend', '${Receptor.getColorFromNum(noteData)} hold end');
			sprite.animation.addByPrefix('${Receptor.getColorFromNum(noteData)}hold', '${Receptor.getColorFromNum(noteData)} hold piece');
		}

		sprite.setGraphicSize(Std.int(sprite.width * 0.7));
		sprite.updateHitbox();
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
