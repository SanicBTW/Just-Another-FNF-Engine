package funkin.notes;

import base.Conductor;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.notes.Receptor.ReceptorData;

class StrumLine extends FlxTypedGroup<FlxBasic>
{
	public var receptors(default, null):FlxTypedGroup<Receptor>;
	public var notesGroup(default, null):FlxTypedGroup<Note>;
	public var holdGroup(default, null):FlxTypedGroup<Note>;
	public var allNotes(default, null):FlxTypedGroup<Note>;

	public var onBotHit(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
	public var onMiss(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

	public var botPlay:Bool = false;

	public var keyAmount:Int = 4;
	public var receptorData:ReceptorData;

	public function new(X:Float = 0, Y:Float = 0, ?strumLineType:String = 'default')
	{
		super();

		receptors = new FlxTypedGroup<Receptor>();
		notesGroup = new FlxTypedGroup<Note>();
		holdGroup = new FlxTypedGroup<Note>();
		allNotes = new FlxTypedGroup<Note>();

		receptorData = Note.returnNoteData(strumLineType);
		keyAmount = receptorData.keyAmount;

		for (i in 0...keyAmount)
		{
			var receptor:Receptor = new Receptor(receptorData, i);
			receptor.ID = i;

			receptor.setGraphicSize(Std.int(receptor.width * receptorData.size));
			receptor.updateHitbox();
			receptor.swagWidth = receptorData.separation * receptorData.size;

			receptor.setPosition(X - receptor.swagWidth / 2, Y - receptor.swagWidth / 2);
			receptor.noteData = i;
			receptor.antialiasing = receptorData.antialiasing;

			receptor.x += (i - ((keyAmount - 1) / 2)) * receptor.swagWidth;
			receptors.add(receptor);

			receptor.initialX = Math.floor(receptor.x);
			receptor.initialY = Math.floor(receptor.y);
			receptor.playAnim('static');

			receptor.y -= 32;
			receptor.alpha = 0;

			FlxTween.tween(receptor, {y: receptor.initialY, alpha: receptor.setAlpha}, (Conductor.crochet * 4) / 1000,
				{ease: FlxEase.circOut, startDelay: (Conductor.crochet / 1000) + ((Conductor.stepCrochet / 1000) * i)});
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

		if (note.parent != null)
		{
			if (note.parent.tail.contains(note))
				note.parent.tail.remove(note);

			if (note.parent.unhitTail.contains(note))
				note.parent.unhitTail.remove(note);
		}

		note.destroy();
	}

	override public function update(elapsed:Float)
	{
		var downscrollMultiplier:Int = 1;

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

			var receptor:Receptor = receptors.members[Math.floor(strumNote.noteData)];
			var receptorY:Float = receptor.y + (Note.swagWidth / 6);

			var pseudoY:Float = strumNote.offsetY + (downscrollMultiplier * -((Conductor.songPosition - strumNote.strumTime) * Conductor.songSpeed));

			strumNote.x = receptor.x
				+ (Math.cos(FlxAngle.asRadians(receptor.direction)) * strumNote.offsetX)
				+ (Math.sin(FlxAngle.asRadians(receptor.direction)) * pseudoY);

			strumNote.y = receptorY
				+ (Math.cos(FlxAngle.asRadians(receptor.direction)) * pseudoY)
				+ (Math.sin(FlxAngle.asRadians(receptor.direction)) * strumNote.offsetX);

			strumNote.angle = -receptor.direction;

			var center:Float = receptorY + Note.swagWidth / 2;
			if (strumNote.isSustain)
			{
				strumNote.y -= ((strumNote.height / 2) * downscrollMultiplier);

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

			if (botPlay && !strumNote.tooLate && strumNote.strumTime <= Conductor.songPosition)
				onBotHit.dispatch(strumNote);

			if ((strumNote.y < -strumNote.height) && (strumNote.tooLate || strumNote.wasGoodHit))
			{
				destroyNote(strumNote);
			}
		});

		super.update(elapsed);
	}
}
