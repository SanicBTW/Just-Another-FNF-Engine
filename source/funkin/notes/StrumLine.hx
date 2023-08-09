package funkin.notes;

import base.Conductor;
import base.sprites.DepthSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.notes.Receptor.ReceptorData;

class StrumLine extends FlxSpriteGroup
{
	public var receptors(default, null):FlxTypedSpriteGroup<Receptor>;
	public var noteSplashes(default, null):FlxTypedSpriteGroup<DepthSprite>;

	public var notesGroup(default, null):FlxTypedSpriteGroup<Note>;
	public var holdGroup(default, null):FlxTypedSpriteGroup<Note>;
	public var allNotes(default, null):FlxTypedSpriteGroup<Note>;

	public var onBotHit(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
	public var onMiss(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

	public var botPlay:Bool = false;

	public var keyAmount:Int = 4;
	public var receptorData:ReceptorData;

	public function new(X:Float = 0, Y:Float = 0, ?strumLineType:String = 'default', ?overrideSize:Float)
	{
		super();

		receptors = new FlxTypedSpriteGroup<Receptor>();

		notesGroup = new FlxTypedSpriteGroup<Note>();
		holdGroup = new FlxTypedSpriteGroup<Note>();
		allNotes = new FlxTypedSpriteGroup<Note>();

		receptorData = Note.returnNoteData(strumLineType);
		keyAmount = receptorData.keyAmount;

		for (i in 0...keyAmount)
		{
			var receptor:Receptor = new Receptor(receptorData, i);
			receptor.ID = i;

			receptor.setGraphicSize(Std.int(receptor.width * receptorData.size));
			receptor.updateHitbox();
			receptor.swagWidth = receptorData.separation * receptorData.size;
			if (overrideSize != null)
			{
				receptor.setGraphicSize(Std.int((receptor.width / receptorData.size) * overrideSize));
				receptor.updateHitbox();
				receptor.swagWidth = receptorData.separation * overrideSize;
			}

			receptor.setPosition(X - receptor.swagWidth / 2, Y - receptor.swagWidth / 2);
			receptor.noteData = i;
			receptor.antialiasing = receptorData.antialiasing;

			receptor.x += (i - ((keyAmount - 1) / 2)) * receptor.swagWidth;
			receptors.add(receptor);

			receptor.initialX = Math.floor(receptor.x);
			receptor.initialY = Math.floor(receptor.y);
			receptor.playAnim('static');
		}

		add(holdGroup);
		add(receptors);
		add(notesGroup);

		if (Settings.showNoteSplashes)
		{
			noteSplashes = new FlxTypedSpriteGroup<DepthSprite>();
			add(noteSplashes);
		}
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
		}

		note.destroy();
	}

	public function generateSplash(noteType:String, noteData:Int)
	{
		var module:backend.ScriptHandler.ForeverModule = Note.returnNoteScript(noteType);
		if (Settings.showNoteSplashes && module.exists("generateSplash"))
		{
			var splashNote:DepthSprite = noteSplashes.recycle(DepthSprite, function()
			{
				var splashNote:DepthSprite = new DepthSprite();
				return splashNote;
			});

			splashNote.alpha = 1;
			splashNote.visible = true;
			splashNote.scale.set(1, 1);
			splashNote.x = receptors.members[noteData].x;
			splashNote.y = receptors.members[noteData].y;

			module.get("generateSplash")(splashNote, noteData);

			if (splashNote.animation != null)
			{
				splashNote.animation.finishCallback = function(name:String)
				{
					splashNote.kill();
				}
			}

			splashNote.z = -Conductor.songPosition;
			noteSplashes.sort(DepthSprite.depthSorting, flixel.util.FlxSort.DESCENDING);
		}
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
			var center:Float = receptor.y + (receptor.swagWidth / 2);

			// math shit lmao
			var receptorY:Float = receptor.y + (receptor.swagWidth / 4);
			var pseudoY:Float = strumNote.offsetY + (downscrollMultiplier * -((Conductor.songPosition - strumNote.strumTime) * Conductor.songSpeed));

			strumNote.x = receptor.x
				+ (Math.cos(FlxAngle.asRadians(receptor.direction)) * strumNote.offsetX)
				+ (Math.sin(FlxAngle.asRadians(receptor.direction)) * pseudoY);

			strumNote.y = receptorY
				+ (Math.cos(FlxAngle.asRadians(receptor.direction)) * pseudoY)
				+ (Math.sin(FlxAngle.asRadians(receptor.direction)) * strumNote.offsetX);

			strumNote.angle = -receptor.direction;

			if (strumNote.isSustain)
			{
				strumNote.y -= ((receptor.swagWidth / 2) * downscrollMultiplier);

				if (strumNote.isSustainEnd && strumNote.prevNote != null && strumNote.prevNote.isSustain)
					strumNote.y += Math.ceil(strumNote.prevNote.y - (strumNote.y + strumNote.height)) + 3;

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

			if (strumNote.tooLate && strumNote.mustPress && strumNote.strumTime - Conductor.songPosition < -166 && !strumNote.wasGoodHit)
			{
				// If it is a single note
				if (!strumNote.isSustain)
					onMiss.dispatch(strumNote);

				// If the hold parent is the prev note (lil hack cuz the first part of the hold is sustain but the head isnt)
				if (strumNote.isSustain && strumNote.parent == strumNote.prevNote)
				{
					for (note in strumNote.parent.tail)
					{
						note.holdActive = false;
						onMiss.dispatch(note);
					}
				}
				else
				{
					if (!strumNote.wasGoodHit
						&& strumNote.isSustain
						&& strumNote.holdActive
						&& strumNote.spotHold != strumNote.parent.tail.length)
					{
						for (note in strumNote.parent.tail)
						{
							note.holdActive = false;
							onMiss.dispatch(note);
						}
					}
				}
			}

			// Dunno if I should handle the botplay timing here
			if (botPlay && !strumNote.tooLate)
			{
				switch (Settings.ratingStyle)
				{
					case KADE:
						if (strumNote.strumTime <= Conductor.songPosition)
							onBotHit.dispatch(strumNote);
					case PSYCH:
						if (strumNote.strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * .5))
							if ((strumNote.isSustain && strumNote.prevNote.wasGoodHit) || strumNote.strumTime <= Conductor.songPosition)
								onBotHit.dispatch(strumNote);
				}
			}

			if ((strumNote.y < -strumNote.height) && (strumNote.tooLate || strumNote.wasGoodHit))
			{
				destroyNote(strumNote);
			}
		});

		super.update(elapsed);
	}
}
