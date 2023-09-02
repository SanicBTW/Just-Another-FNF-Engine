package funkin.notes;

import backend.Conductor;
import base.sprites.DepthSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.notes.Receptor.ReceptorData;

class StrumLine extends FlxSpriteGroup
{
	public var receptors(default, null):FlxTypedSpriteGroup<Receptor>;
	public var splashes(default, null):FlxTypedSpriteGroup<DepthSprite>;

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
		if (Settings.showNoteSplashes)
			splashes = new FlxTypedSpriteGroup<DepthSprite>();

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

			if (Settings.showNoteSplashes)
				generateSplash(receptor, true);
		}

		add(holdGroup);
		add(receptors);
		add(notesGroup);

		if (Settings.showNoteSplashes)
			add(splashes);
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

	public function generateSplash(receptor:Receptor, preload:Bool = false)
	{
		var module:backend.scripting.ForeverModule = Note.returnNoteScript(receptor.noteType);
		if (Settings.showNoteSplashes && module.exists("generateSplash"))
		{
			var splashNote:DepthSprite = splashes.recycle(DepthSprite, function()
			{
				var splashNote:DepthSprite = new DepthSprite();
				return splashNote;
			});

			splashNote.alpha = 1;
			splashNote.visible = !preload;
			splashNote.scale.set(1, 1);
			splashNote.updateHitbox();

			splashNote.x = receptors.members[receptor.noteData].x;
			splashNote.y = receptors.members[receptor.noteData].y;

			module.get("generateSplash")(splashNote, receptor.noteData);

			if (splashNote.animation != null)
			{
				splashNote.animation.finishCallback = function(name:String)
				{
					splashNote.kill();
				}
			}

			splashNote.z = -Conductor.time;
			splashes.sort(DepthSprite.depthSorting, flixel.util.FlxSort.DESCENDING);
		}
	}

	override public function update(elapsed:Float)
	{
		var downscrollMultiplier:Int = (!Settings.downScroll ? 1 : -1) * flixel.math.FlxMath.signOf(Conductor.speed);
		var realSpeed:Float = (Conductor.speed / Conductor.rate);

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

			var receptor:Receptor = receptors.members[strumNote.noteData];

			var receptorX:Float = receptor.x + strumNote.offsetX;
			var receptorY:Float = receptor.y + strumNote.offsetY;
			var receptorA:Float = receptor.angle;
			var receptorD:Float = receptor.direction;

			var angleDir:Float = receptorD * (Math.PI / 180);
			var dist:Float = ((Conductor.rate * downscrollMultiplier) * -(Conductor.time - strumNote.strumTime) * realSpeed);

			strumNote.angle = receptorD - 90 + receptorA;

			strumNote.x = receptorX + Math.cos(angleDir) * dist;
			strumNote.y = receptorY + Math.sin(angleDir) * dist;

			var center:Float = receptor.y + (receptor.swagWidth / 2);
			if (strumNote.isSustain)
			{
				strumNote.y -= ((receptor.swagWidth / 2) * downscrollMultiplier);

				if (Settings.downScroll)
				{
					if (strumNote.isSustainEnd)
					{
						strumNote.y += (receptor.swagWidth / 2);

						if (strumNote.endHoldOffset == Math.NEGATIVE_INFINITY)
							strumNote.endHoldOffset = Math.ceil((strumNote.prevNote.y - (strumNote.y + strumNote.height)) + 3);
						else
							strumNote.y += strumNote.endHoldOffset;
					}

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

			if (strumNote.tooLate && strumNote.mustPress && strumNote.strumTime - Conductor.time < -166 && !strumNote.wasGoodHit)
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
						if (strumNote.strumTime <= Conductor.time)
							onBotHit.dispatch(strumNote);
					case PSYCH:
						if (strumNote.strumTime < Conductor.time + (Conductor.safeZoneOffset * .5))
							if ((strumNote.isSustain && strumNote.prevNote.wasGoodHit) || strumNote.strumTime <= Conductor.time)
								onBotHit.dispatch(strumNote);
				}
			}

			if ((!Settings.downScroll
				&& (strumNote.y < -strumNote.height)
				|| Settings.downScroll
				&& (strumNote.y > (flixel.FlxG.height + strumNote.height)))
				&& (strumNote.tooLate || strumNote.wasGoodHit))
			{
				destroyNote(strumNote);
			}
		});

		super.update(elapsed);
	}
}
