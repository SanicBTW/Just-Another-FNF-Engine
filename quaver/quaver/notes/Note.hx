package quaver.notes;

import backend.Conductor;
import flixel.FlxSprite;
import states.ScrollTest;

// Sync with stable source
@:publicFields
class Note extends FlxSprite
{
	public static var swagWidth:Float = 160 * 0.7;

	var stepTime:Float;

	var strumTime(get, null):Float;

	@:noCompletion
	private function get_strumTime()
		return (stepTime * Conductor.stepCrochet);

	var noteData:Int = 0;
	var tooLate:Bool = false;
	var canBeHit:Bool = false;
	var wasGoodHit:Bool = false;
	var mustPress:Bool = false;
	var strumLine:Int = 0;

	var prevNote:Note;
	var head:Note = null;
	var tail:Array<Note> = [];
	var sustainLength:Int = 0;

	var isSustain:Bool = false;
	var isSustainEnd:Bool = false;

	var holdTime:Float = 0;
	var holding:Bool = false;

	var isVisible:Bool = false;

	function new(stepTime:Float, noteData:Int, ?prevNote:Note, isSustain:Bool = false)
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
			frames = ScrollTest.Paths.getSparrowAtlas('NOTE_assets');
			loadNoteAnims();
			x += swagWidth * noteData;
			if (!isSustain)
				animation.play('${Receptor.getColorFromNum(noteData)}Scroll');
		}

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
			}
		}
	}

	private function loadNoteAnims()
	{
		var color:String = Receptor.getColorFromNum(noteData);
		animation.addByPrefix('${color}Scroll', '${color}0');

		if (isSustain)
		{
			animation.addByPrefix('${color}hold', '${color} hold piece');
			animation.addByPrefix('${color}holdend', '${color} hold end');
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}
}
