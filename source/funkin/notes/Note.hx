package funkin.notes;

import base.system.Conductor;
import flixel.FlxSprite;

class Note extends FlxSprite
{
	public static var swagWidth:Float = 160 * 0.7;

	public var strumTime:Float;
	public var noteData:Int = 0;
	public var tooLate:Bool = false;
	public var canBeHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var mustPress:Bool = false;
	public var doubleNote:Bool = false;
	public var strumLine:Int = 0;
	public var prevNote:Note;

	public var parent:Note = null;
	public var children:Array<Note> = [];
	public var isSustain:Bool = false;
	public var isSustainEnd:Bool = false;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public function new(strumTime:Float, noteData:Int, strumLine:Int, ?prevNote:Note, ?isSustain:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.isSustain = isSustain;
		this.noteData = noteData;
		this.strumTime = strumTime;
		this.strumLine = strumLine;

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

		if (isSustain && prevNote != null)
		{
			alpha = 0.6;
			offsetX += width / 2;

			animation.play('${Receptor.getColorFromNum(noteData)}holdend');
			updateHitbox();

			offsetX -= width / 2;

			if (prevNote.isSustain)
			{
				prevNote.animation.play('${Receptor.getColorFromNum(noteData)}hold');
				prevNote.updateHitbox();

				prevNote.scale.y *= ((Conductor.stepCrochet / 100) * (1.06 / 0.7)) * (Conductor.songSpeed / 0.45);
				prevNote.updateHitbox();
			}
		}
		x += offsetX;
	}

	private function loadNoteAnims(sprite:Note, noteData:Int, isSustainNote:Bool)
	{
		sprite.animation.addByPrefix('${Receptor.getColorFromNum(noteData)}Scroll', '${Receptor.getColorFromNum(noteData)}0');

		if (isSustainNote)
		{
			sprite.animation.addByPrefix('${Receptor.getColorFromNum(noteData)}holdend', '${Receptor.getColorFromNum(noteData)} hold end');
			sprite.animation.addByPrefix('${Receptor.getColorFromNum(noteData)}hold', '${Receptor.getColorFromNum(noteData)} hold piece');
		}

		sprite.setGraphicSize(Std.int(sprite.width * 0.7));
		sprite.updateHitbox();
	}

	public function updateSustainScale(ratio:Float)
	{
		if (isSustain)
		{
			if (prevNote != null)
			{
				if (prevNote.isSustain)
				{
					prevNote.scale.y *= ratio;
					prevNote.updateHitbox();
					offsetX = prevNote.offsetX;
				}
				else
					offsetX = ((prevNote.width / 2) - (width / 2));
			}
		}
	}

	override function update(elapsed:Float)
	{
		if (mustPress)
		{
			if (isSustain)
			{
				if (strumTime - Conductor.songPosition <= ((166 * Conductor.timeScale) * 0.5)
					&& strumTime - Conductor.songPosition >= (-166 * Conductor.timeScale))
					canBeHit = true;
				else
					canBeHit = false;
			}
			else
			{
				if (strumTime - Conductor.songPosition <= (166 * Conductor.timeScale)
					&& strumTime - Conductor.songPosition >= (-166 * Conductor.timeScale))
					canBeHit = true;
				else
					canBeHit = false;
			}
		}

		if (tooLate && !wasGoodHit)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}

		super.update(elapsed);
	}
}
