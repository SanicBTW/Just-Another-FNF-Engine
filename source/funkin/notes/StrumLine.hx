package funkin.notes;

import base.Conductor;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal.FlxTypedSignal;
import states.PlayTest;

class StrumLine extends FlxTypedGroup<FlxBasic>
{
	public var receptors(default, null):FlxTypedGroup<Receptor>;
	public var notesGroup(default, null):FlxTypedGroup<Note>;
	public var holdGroup(default, null):FlxTypedGroup<Note>;
	public var allNotes(default, null):FlxTypedGroup<Note>;

	public var onBotHit(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

	public var botPlay:Bool = false;
	public var lineSpeed:Float = 0;
	public var downScroll:Bool = false;

	public function new(x:Float = 0, keyAmount:Int = 4)
	{
		super();

		receptors = new FlxTypedGroup<Receptor>();
		notesGroup = new FlxTypedGroup<Note>();
		holdGroup = new FlxTypedGroup<Note>();
		allNotes = new FlxTypedGroup<Note>();

		for (i in 0...keyAmount)
		{
			var receptor:Receptor = new Receptor(x, 60, i);
			receptor.ID = i;

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

	public function push(newNote:Note)
	{
		(newNote.isSustain ? holdGroup.add(newNote) : notesGroup.add(newNote));
		allNotes.add(newNote);
	}

	public function destroyNote(note:Note)
	{
		note.active = false;
		note.exists = false;

		note.kill();
		allNotes.remove(note, true);
		(note.isSustain ? holdGroup.remove(note, true) : notesGroup.remove(note, true));
		note.destroy();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var downscrollMultiplier:Int = (!downScroll ? 1 : -1) * FlxMath.signOf(lineSpeed);

		allNotes.forEachAlive(function(strumNote:Note)
		{
			if (strumNote.tooLate)
			{
				strumNote.active = false;
				strumNote.visible = false;
			}

			strumNote.noteSpeed = Math.abs(lineSpeed);
			var baseX:Float = receptors.members[Math.floor(strumNote.noteData)].x;
			var baseY:Float = receptors.members[Math.floor(strumNote.noteData)].y;
			strumNote.x = baseX + strumNote.offsetX;
			strumNote.y = baseY
				+ strumNote.offsetY
				+ (downscrollMultiplier * -((Conductor.songPosition - (strumNote.stepTime * Conductor.stepCrochet)) * (0.45 * lineSpeed)));

			var center:Float = baseY + (Note.swagWidth / 2);
			if (strumNote.isSustain)
			{
				strumNote.y -= ((Note.swagWidth / 2) * downscrollMultiplier);

				if (downscrollMultiplier < 0)
				{
					strumNote.flipY = true;
					if (strumNote.y - strumNote.offset.y * strumNote.scale.y + strumNote.height >= center
						&& (botPlay || (strumNote.wasGoodHit || (strumNote.prevNote != null && strumNote.prevNote.wasGoodHit))))
					{
						var swagRect = new FlxRect(0, 0, strumNote.frameWidth, strumNote.frameHeight);
						swagRect.height = (center - strumNote.y) / strumNote.scale.y;
						swagRect.y = strumNote.frameHeight - swagRect.height;
						strumNote.clipRect = swagRect;
					}
				}
				else if (downscrollMultiplier > 0)
				{
					if (strumNote.y + strumNote.offset.y * strumNote.scale.y <= center
						&& (botPlay || (strumNote.wasGoodHit || (strumNote.prevNote != null && strumNote.prevNote.wasGoodHit))))
					{
						var swagRect = new FlxRect(0, 0, strumNote.width / strumNote.scale.x, strumNote.height / strumNote.scale.y);
						swagRect.y = (center - strumNote.y) / strumNote.scale.y;
						swagRect.height -= swagRect.y;
						strumNote.clipRect = swagRect;
					}
				}
			}

			// goofy
			if (botPlay
				&& !strumNote.tooLate
				&& strumNote.stepTime * Conductor.stepCrochet <= Conductor.songPosition
				|| (!strumNote.mustPress && strumNote.wasGoodHit))
				onBotHit.dispatch(strumNote);

			if ((strumNote.y < -strumNote.height || strumNote.y > FlxG.height + strumNote.height)
				&& (strumNote.tooLate || strumNote.wasGoodHit))
			{
				destroyNote(strumNote);
			}
		});
	}
}
