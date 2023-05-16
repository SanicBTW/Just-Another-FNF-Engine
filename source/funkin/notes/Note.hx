package funkin.notes;

import base.Conductor;
import flixel.FlxSprite;

class Note extends FlxSprite
{
	public static var swagWidth:Float = 160 * 0.7;

	public var strumTime:Float;
	public var noteData:Int = 0;
	public var tooLate:Bool = false;
	public var canBeHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var mustPress:Bool = false;

	public var doubleNote:Bool = false;
	public var strumLine:Int = 0;
	public var prevNote:Note;

	public var parent:Note = null;
	public var children:Array<Note> = [];
	public var isSustain:Bool = false;
	public var isSustainEnd:Bool = false;
	public var sustainLength:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var noteType(default, set):String = null;
	public var texture(default, set):String = null;

	public var endHoldOffset:Float = Math.NEGATIVE_INFINITY;

	@:noCompletion
	private function set_texture(value:String):String
	{
		if (texture != value)
			reloadNote('', value);

		texture = value;
		return value;
	}

	@:noCompletion
	private function set_noteType(value:String):String
	{
		if (noteData > -1 && noteType != value)
		{
			switch (value) {}
		}

		return value;
	}

	public function new(strumTime:Float, noteData:Int, strumLine:Int, ?prevNote:Note, ?isSustain:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.strumTime = strumTime;
		this.noteData = noteData;
		this.strumLine = strumLine;

		this.prevNote = prevNote;
		this.isSustain = isSustain;

		y -= 2000;

		if (noteData > -1)
		{
			texture = '';
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

				prevNote.scale.y *= ((Conductor.stepCrochet / 100) * (1.055 / 0.7)) * (Conductor.songSpeed / Conductor.songRate);
				prevNote.updateHitbox();
			}
		}

		x += offsetX;
	}

	private function reloadNote(prefix:String = '', texture:String = '', suffix:String = '')
	{
		if (prefix == null)
			prefix = '';
		if (texture == null)
			texture = '';
		if (suffix == null)
			suffix = '';

		var skin:String = texture;
		if (texture.length < 1)
		{
			skin = Conductor.SONG.arrowSkin;
			if (skin == null || skin.length < 1)
				skin = 'NOTE_assets';
		}

		var animName:String = null;
		if (animation.curAnim != null)
			animName = animation.curAnim.name;

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length - 1] = prefix + arraySkin[arraySkin.length - 1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');

		frames = Paths.getSparrowAtlas(blahblah);
		loadNoteAnims();
		antialiasing = true;

		if (isSustain)
			scale.y = lastScaleY;

		updateHitbox();

		if (animName != null)
			animation.play(animName, true);
	}

	private function loadNoteAnims()
	{
		var color:String = Receptor.getColorFromNum(noteData);
		animation.addByPrefix('${color}Scroll', '${color}0');

		if (isSustain)
		{
			animation.addByPrefix('${color}hold', '$color hold piece');
			animation.addByPrefix('${color}holdend', '$color hold end');
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		if (mustPress)
		{
			if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}

		if (tooLate || (parent != null && parent.tooLate))
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}

		super.update(elapsed);
	}
}
