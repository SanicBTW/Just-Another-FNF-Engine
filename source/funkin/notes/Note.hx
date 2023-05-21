package funkin.notes;

import base.Conductor;
import flixel.FlxSprite;

class Note extends FlxSprite
{
	public static var swagWidth:Float = 160 * 0.7;

	// Vanilla
	public var strumTime:Float;
	public var noteData:Int = 0;
	public var tooLate:Bool = false;
	public var canBeHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var mustPress:Bool = false;
	public var isSustain:Bool = false;
	public var isSustainEnd:Bool = false;
	public var sustainLength:Float = 0;
	public var prevNote:Note;

	// Psych
	public var ignoreNote:Bool = false;

	// FE:R
	public var strumLine:Int = 0;

	// JAFE
	public var doubleNote:Bool = false;

	// Sustains (Andromeda:L - HOLDS V2)
	public var parent:Note;
	public var tail:Array<Note> = [];
	public var unhitTail:Array<Note> = [];
	public var tripTimer:Float = 1;
	public var holdingTime:Float = 0;

	// Andromeda:L
	public var gcTime:Float = 200;
	public var garbage:Bool = false;
	public var hitbox:Float = 166;

	// Psych
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	// Psych
	public var noteType(default, set):String = null;
	public var texture(default, set):String = null;

	// FE:L
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
			noteType = value;
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

				prevNote.scale.y *= ((Conductor.stepCrochet / 100) * 1.5) * (Conductor.songSpeed / Conductor.songRate);
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
			var diff:Float = Math.abs(strumTime - Conductor.songPosition);

			if (isSustain)
				canBeHit = (diff <= hitbox * .5);
			else
				canBeHit = (diff <= hitbox);

			tooLate = (diff < -Conductor.safeZoneOffset && !wasGoodHit);
		}

		if (tooLate || (parent != null && parent.tooLate))
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}

		super.update(elapsed);
	}
}
