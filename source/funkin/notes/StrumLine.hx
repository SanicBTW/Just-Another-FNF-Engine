package funkin.notes;

import base.system.Conductor;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal.FlxTypedSignal;

// Moved to Forever Engine Legacy Note Calls
class StrumLine extends FlxTypedGroup<FlxBasic>
{
	public var receptors(default, null):FlxTypedGroup<Receptor>;
	public var splashNotes(default, null):FlxTypedGroup<NoteSplash>;
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
		splashNotes = new FlxTypedGroup<NoteSplash>();
		notesGroup = new FlxTypedGroup<Note>();
		holdGroup = new FlxTypedGroup<Note>();
		allNotes = new FlxTypedGroup<Note>();

		for (i in 0...keyAmount)
		{
			var receptor:Receptor = new Receptor(x, (SaveData.downScroll ? FlxG.height - 150 : 50), i);
			receptor.ID = i;

			receptor.x -= ((keyAmount / 2) * Note.swagWidth);
			receptor.x += (Note.swagWidth * i);
			receptors.add(receptor);

			receptor.initialX = Math.floor(receptor.x);
			receptor.initialY = Math.floor(receptor.y);
			receptor.playAnim('static');

			receptor.y -= 32;
			receptor.alpha = 0;

			FlxTween.tween(receptor, {y: receptor.initialY, alpha: receptor.setAlpha}, (Conductor.crochet * 4) / 1000,
				{ease: FlxEase.circOut, startDelay: (Conductor.crochet / 1000) + ((Conductor.stepCrochet / 1000) * i)});

			var splash:NoteSplash = new NoteSplash(receptor.initialX, receptor.initialY, i);
			splashNotes.add(splash);
		}

		add(holdGroup);
		add(receptors);
		add(notesGroup);
		add(splashNotes);
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

		var downscrollMultiplier:Int = (!SaveData.downScroll ? 1 : -1);

		for (receptor in receptors)
		{
			if (botPlay && receptor.animation.finished)
				receptor.playAnim('static');
		}

		allNotes.forEachAlive(function(strumNote:Note)
		{
			var receptorX:Float = receptors.members[Math.floor(strumNote.noteData)].x;
			var receptorY:Float = receptors.members[Math.floor(strumNote.noteData)].y + (Note.swagWidth / 6);

			var pseudoX:Float = strumNote.offsetX;
			var pseudoY:Float = strumNote.offsetY + (downscrollMultiplier * -((Conductor.songPosition - strumNote.strumTime) * Conductor.songSpeed));

			strumNote.y = receptorY
				+ (Math.cos(FlxAngle.asRadians(strumNote.direction)) * pseudoY)
				+ (Math.sin(FlxAngle.asRadians(strumNote.direction)) * pseudoX);

			strumNote.x = receptorX
				+ (Math.cos(FlxAngle.asRadians(strumNote.direction)) * pseudoX)
				+ (Math.sin(FlxAngle.asRadians(strumNote.direction)) * pseudoY);

			strumNote.angle = -strumNote.direction;

			var center:Float = receptorY + Note.swagWidth / 2;
			if (strumNote.isSustain)
			{
				strumNote.y -= ((strumNote.height / 2) * downscrollMultiplier);
				if (strumNote.isSustainEnd && strumNote.prevNote != null)
				{
					strumNote.y -= ((strumNote.prevNote.height / 2) * downscrollMultiplier);
					if (SaveData.downScroll)
					{
						strumNote.y += (strumNote.height * 2);
						strumNote.y += (strumNote.prevNote.y - (strumNote.y + strumNote.height));
						/*
							if (downscrollMultiplier < 0)
							{
								// Might be wrong on this type of note: Note - Sustain end, because it cant get the previous note Y pos, if it does then the sustain end will stay visible for some reason
								if (strumNote.isSustainEnd && strumNote.prevNote.isSustain)
									strumNote.y += Math.ceil(strumNote.prevNote.y - (strumNote.y + strumNote.height)) + 3;
						 */
					}
					else
						strumNote.y += ((strumNote.height / 2) * downscrollMultiplier);
				}

				if (SaveData.downScroll)
				{
					strumNote.flipY = true;
					if ((strumNote.parent != null && strumNote.parent.wasGoodHit)
						&& strumNote.y - strumNote.offset.y * strumNote.scale.y + strumNote.height >= center
						&& (botPlay || (strumNote.wasGoodHit || (strumNote.prevNote.wasGoodHit && !strumNote.canBeHit))))
					{
						var swagRect = new FlxRect(0, 0, strumNote.frameWidth, strumNote.frameHeight);
						swagRect.height = (center - strumNote.y) / strumNote.scale.y;
						swagRect.y = strumNote.frameHeight - swagRect.height;
						strumNote.clipRect = swagRect;
					}
				}
				else
				{
					if ((strumNote.parent != null && strumNote.parent.wasGoodHit)
						&& strumNote.y + strumNote.offset.y * strumNote.scale.y <= center
						&& (botPlay || (strumNote.wasGoodHit || (strumNote.prevNote.wasGoodHit && !strumNote.canBeHit))))
					{
						var swagRect = new FlxRect(0, 0, strumNote.width / strumNote.scale.x, strumNote.height / strumNote.scale.y);
						swagRect.y = (center - strumNote.y) / strumNote.scale.y;
						swagRect.height -= swagRect.y;
						strumNote.clipRect = swagRect;
					}
				}
			}

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

			if (!strumNote.tooLate
				&& strumNote.mustPress
				&& strumNote.strumTime - Conductor.songPosition < -166
				&& !strumNote.wasGoodHit)
			{
				// If it is a single note or is the head of the sustain
				if (!strumNote.isSustain || strumNote.parent == null)
				{
					strumNote.tooLate = true;
					onMiss.dispatch(strumNote);
				}
				else if (strumNote.isSustain && strumNote.parent != null)
				{
					// bro this shit is so fucking strict omg
					var parent:Note = strumNote.parent;
					if (!parent.tooLate)
					{
						for (i in 0...parent.children.length)
						{
							var child:Note = parent.children[i];
							if (!child.wasGoodHit && i != parent.children.length)
							{
								child.tooLate = true;
							}
						}
						onMiss.dispatch(parent);
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
