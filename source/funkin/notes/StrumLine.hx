package funkin.notes;

import base.Conductor;
import base.SaveData;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal.FlxTypedSignal;

class StrumLine extends FlxTypedGroup<FlxBasic>
{
	public var receptors(default, null):FlxTypedGroup<Receptor>;
	public var notesGroup(default, null):FlxTypedGroup<Note>;
	public var holdGroup(default, null):FlxTypedGroup<Note>;
	public var allNotes(default, null):FlxTypedGroup<Note>;

	public var onBotHit(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
	public var onMiss(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

	public var botPlay:Bool = false;

	public function new(x:Float = 0, keyAmount:Int = 4)
	{
		super();

		receptors = new FlxTypedGroup<Receptor>();
		notesGroup = new FlxTypedGroup<Note>();
		holdGroup = new FlxTypedGroup<Note>();
		allNotes = new FlxTypedGroup<Note>();

		for (i in 0...keyAmount)
		{
			var receptor:Receptor = new Receptor(x, (SaveData.downScroll ? FlxG.height - 150 : 60), i);
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

		var downscrollMultiplier:Int = (!SaveData.downScroll ? 1 : -1) * FlxMath.signOf(Conductor.songSpeed / 0.45);

		for (receptor in receptors)
		{
			if (botPlay && receptor.animation.finished)
				receptor.playAnim('static');
		}

		allNotes.forEachAlive(function(strumNote:Note)
		{
			if (strumNote.tooLate)
			{
				strumNote.active = false;
				strumNote.visible = false;
			}

			var baseX:Float = receptors.members[Math.floor(strumNote.noteData)].x;
			var baseY:Float = receptors.members[Math.floor(strumNote.noteData)].y;
			strumNote.x = baseX + strumNote.offsetX;
			strumNote.y = baseY + strumNote.offsetY + (downscrollMultiplier * -((Conductor.songPosition - strumNote.strumTime) * Conductor.songSpeed));

			var center:Float = baseY + (Note.swagWidth / 2);
			if (strumNote.isSustain)
			{
				strumNote.y -= ((Note.swagWidth / 2) * downscrollMultiplier);

				if (strumNote.prevNote != null)
				{
					strumNote.y -= Math.ceil(strumNote.prevNote.y - (strumNote.y + strumNote.height) + 1.5);
				}

				if (downscrollMultiplier < 0)
				{
					if (strumNote.isSustainEnd)
						strumNote.y += Math.ceil(strumNote.prevNote.y - (strumNote.y + strumNote.height)) + 1.5;

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

			if (!strumNote.tooLate && strumNote.strumTime < (Conductor.songPosition - Timings.Threshold) && !strumNote.wasGoodHit)
			{
				strumNote.tooLate = true;

				if (!strumNote.isSustain)
				{
					for (note in strumNote.children)
						note.tooLate = true;
					onMiss.dispatch(strumNote);
				}
				else
				{
					if (strumNote.parent != null)
					{
						var parent:Note = strumNote.parent;
						if (!parent.tooLate)
						{
							var breakLate:Bool = false;
							for (note in parent.children)
							{
								if (note.tooLate && !note.wasGoodHit)
									breakLate = true;
							}
							if (!breakLate)
							{
								for (note in parent.children)
									note.tooLate;
								onMiss.dispatch(strumNote);
							}
						}
					}
				}
			}

			if (botPlay && !strumNote.tooLate && strumNote.strumTime <= Conductor.songPosition)
				onBotHit.dispatch(strumNote);

			if ((!SaveData.downScroll
				&& (strumNote.y < -strumNote.height)
				|| SaveData.downScroll
				&& (strumNote.y > (FlxG.height + strumNote.height)))
				&& (strumNote.tooLate || strumNote.wasGoodHit))
			{
				destroyNote(strumNote);
			}
		});
	}
}
