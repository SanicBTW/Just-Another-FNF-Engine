package funkin.notes;

import base.Conductor;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import states.PlayTest;

// mix using FlatyEngine/StilicEngine code
class StrumLine extends FlxSpriteGroup
{
	public var receptors:FlxTypedSpriteGroup<Receptor>;
	public var notesGroup:FlxTypedSpriteGroup<Note>;
	public var holdGroup:FlxTypedSpriteGroup<Note>;
	public var allNotes:FlxTypedSpriteGroup<Note>;

	public function new(x:Float = 0, keyAmount:Int = 4)
	{
		super();

		receptors = new FlxTypedSpriteGroup<Receptor>();
		notesGroup = new FlxTypedSpriteGroup<Note>();
		holdGroup = new FlxTypedSpriteGroup<Note>();
		allNotes = new FlxTypedSpriteGroup<Note>();

		for (i in 0...keyAmount)
		{
			var receptor:Receptor = new Receptor(x, 60, i);
			receptor.ID = i;

			receptor.action = Receptor.getArrowFromNum(i);
			receptor.x -= ((keyAmount / 2) * Note.swagWidth);
			receptor.x += (Note.swagWidth * i);
			receptors.add(receptor);

			receptor.initialX = Math.floor(receptor.x);
			receptor.initialY = Math.floor(receptor.y);
			receptor.playAnim('static');

			receptor.y -= 20;
			receptor.alpha = 0;

			FlxTween.tween(receptor, {y: receptor.initialY, alpha: receptor.setAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
		}

		add(holdGroup);
		add(receptors);
		add(notesGroup);
	}

	override public function add(sprite:FlxSprite):FlxSprite
	{
		if (sprite is Note)
		{
			var shitNote = cast(sprite, Note);
			(shitNote.isSustain ? holdGroup.add(shitNote) : notesGroup.add(shitNote));
			return allNotes.add(shitNote);
		}
		return super.add(sprite);
	}
	/*
		override public function update(elapsed:Float)
		{
			super.update(elapsed);

			var fakeCrochet:Float = (60 / PlayTest.SONG.bpm) * 1000;
			var roundedSpeed:Float = FlxMath.roundDecimal(PlayTest.SONG.speed, 2);
			allNotes.forEachAlive(function(strumNote:Note)
			{
				if (strumNote.tooLate)
				{
					strumNote.active = false;
					strumNote.visible = false;
				}
				else
				{
					strumNote.visible = true;
					strumNote.active = true;
				}

				var baseX = receptors.members[Math.floor(strumNote.noteData)].x;
				var baseY = receptors.members[Math.floor(strumNote.noteData)].y;

				strumNote.y = baseY - 0.45 * (Conductor.songPosition - strumNote.stepTime) * roundedSpeed + strumNote.noteYOff;

				var center:Float = baseY + (Note.swagWidth / 2);
				if (strumNote.isSustain)
				{
					strumNote.y -= strumNote.height / 2;

					var swagRect = new FlxRect(0, 0, strumNote.width / strumNote.scale.x, strumNote.height / strumNote.scale.y);
					swagRect.y = (center - strumNote.y) / strumNote.scale.y;
					swagRect.height -= swagRect.y;
					strumNote.clipRect = swagRect;
				}
			});
	}*/
}
