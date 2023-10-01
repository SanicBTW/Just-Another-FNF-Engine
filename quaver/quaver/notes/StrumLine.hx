package quaver.notes;

import backend.Cache;
import backend.Conductor;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using backend.Extensions;

typedef Section =
{
	var header:FlxSprite;
	var body:Array<FlxSprite>;
	var exists:Bool;
	var time:Float;
}

typedef SustainNote =
{
	var holdLength:Float;
	var tail:FlxTypedSpriteGroup<FlxTiledSprite>;
	var exists:Bool;
}

@:publicFields
// NOTE: Apparently when parsing notes, making sustains isn't actually needed as this will create the FlxTiledSprite and scale it to match the sustain length when pushed
// TODO: Events
class StrumLine extends FlxSpriteGroup
{
	static final SEPARATION:Int = 160;
	static final CELL_SIZE:Int = 110;
	static final keyAmount:Int = 4;
	static final swagWidth:Float = SEPARATION * (CELL_SIZE / SEPARATION);

	/**
	 * How many tiles is the camera ahead of the crochet
	 */
	static var CELL_OFFSET:Float = 2.75;

	// Cache graphics, bg and camera
	private var _checkerboard(default, null):FlxGraphic;
	private var _line(default, null):FlxGraphic;
	private var _sectionLine(default, null):FlxGraphic;

	private var _boardPattern(default, null):FlxTiledSprite;
	private var _conductorCrochet(default, null):FlxSprite;

	private var _camFollow:FlxObject;

	// Exposed variables
	var botPlay:Bool = false;

	private var _speedTwn:FlxTween;
	var scrollSpeed(default, set):Float = 1;

	@:noCompletion
	private function set_scrollSpeed(value:Float):Float
	{
		if (_speedTwn != null)
			_speedTwn.cancel();

		_speedTwn = FlxTween.num(scrollSpeed, value, 0.2, {
			ease: FlxEase.linear,
			onComplete: (_) ->
			{
				_speedTwn = null;
			}
		}, function(f:Float)
		{
			scrollSpeed = f;
		});

		return value;
	}

	// Note rendering
	var receptors(default, null):FlxTypedSpriteGroup<Receptor>;
	var noteGroup(default, null):FlxTypedSpriteGroup<Note>;
	var holdGroup(default, null):FlxTypedSpriteGroup<FlxSprite>;

	// Stores sustains
	var holdMap(default, null):Map<Note, SustainNote> = [];

	// Section rendering
	var sectionGroup(default, null):FlxTypedSpriteGroup<FlxSprite>;
	var sectionList:Array<Section> = [];

	function new(X:Float = 0)
	{
		super(X);

		cacheGraphics();

		_camFollow = new FlxObject();

		_boardPattern = new FlxTiledSprite(_checkerboard, CELL_SIZE * keyAmount, CELL_SIZE * 16);
		_boardPattern.setPosition(0, 0);
		_boardPattern.x -= ((keyAmount / 2) * swagWidth);
		_boardPattern.active = false;
		add(_boardPattern);

		sectionGroup = new FlxTypedSpriteGroup<FlxSprite>();
		add(sectionGroup);
		regenSections();

		_conductorCrochet = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		_conductorCrochet.setGraphicSize(Std.int((CELL_SIZE * keyAmount) + CELL_SIZE), 2);
		_conductorCrochet.alpha = 0.5;
		_conductorCrochet.y = CELL_SIZE / 2;
		_conductorCrochet.active = _boardPattern.active;
		add(_conductorCrochet);

		receptors = new FlxTypedSpriteGroup<Receptor>();
		noteGroup = new FlxTypedSpriteGroup<Note>();
		holdGroup = new FlxTypedSpriteGroup<FlxSprite>();

		for (i in 0...keyAmount)
		{
			var receptor:Receptor = new Receptor(0, 0, i);
			receptor.ID = i;

			receptor.setGraphicSize(Std.int((receptor.width / 0.7) * (CELL_SIZE / SEPARATION)));
			receptor.updateHitbox();

			receptor.x -= ((keyAmount / 2) * swagWidth);
			receptor.x += (swagWidth * i);

			receptor.playAnim('static');
			receptors.add(receptor);
		}

		add(holdGroup);
		add(receptors);
		add(noteGroup);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		_boardPattern.height = (((Conductor.boundInst != null) ? Conductor.boundInst.length : flixel.FlxG.sound.music.length / Conductor.stepCrochet) * CELL_SIZE) * scrollSpeed;

		updateCrochet();
		updateSections();
		updateNotes();
		updateCamFollow();
	}

	private function cacheGraphics()
	{
		@:privateAccess
		_checkerboard = FlxGraphic.fromBitmapData(Cache.set(FlxGridOverlay.createGrid(CELL_SIZE, CELL_SIZE, CELL_SIZE * 2, CELL_SIZE * 2, true,
			FlxColor.WHITE, FlxColor.BLACK), BITMAP, 'board$CELL_SIZE'));
		_checkerboard.bitmap.colorTransform(new openfl.geom.Rectangle(0, 0, CELL_SIZE * 2, CELL_SIZE * 2), new openfl.geom.ColorTransform(1, 1, 1, 0.25));

		_sectionLine = Cache.set(FlxG.bitmap.create((CELL_SIZE * keyAmount) + 30, 5, FlxColor.WHITE), GRAPHIC, 'sectionline');
		_line = Cache.set(FlxG.bitmap.create((CELL_SIZE * keyAmount) + 20, 2, FlxColor.WHITE), GRAPHIC, 'chartline');

		for (i in 0...keyAmount)
		{
			var noteHold:Note = new Note(0, i, null, true);
			var noteEnd:Note = new Note(0, i, noteHold, true);

			var frameB:FlxFrame = noteHold.frames.framesHash.get(noteHold.animation.frameName);
			Cache.set(FlxGraphic.fromFrame(frameB), GRAPHIC, 'tail$i-BODY');

			var frameE:FlxFrame = noteEnd.frames.framesHash.get(noteEnd.animation.frameName);
			Cache.set(FlxGraphic.fromFrame(frameE), GRAPHIC, 'tail$i-END');

			noteEnd.destroy();
			noteHold.destroy();
		}
	}

	public function regenSections()
	{
		for (i in sectionGroup)
			i.destroy();

		sectionGroup.clear();

		for (i in 0...Std.int(((Conductor.boundInst != null) ? Conductor.boundInst.length : flixel.FlxG.sound.music.length / Conductor.stepCrochet) / 16))
		{
			// Them header
			var lineSprite:FlxSprite = new FlxSprite(0, 0, _sectionLine);
			lineSprite.alpha = 0.5;
			lineSprite.exists = false;
			sectionGroup.add(lineSprite);

			var curSection:Section = {
				header: lineSprite,
				body: [],
				exists: lineSprite.exists,
				time: (i * 16)
			};

			// Section body lines
			for (j in 1...4)
			{
				var thinLine:FlxSprite = new FlxSprite(0, 0, _line);
				thinLine.alpha = 0.75;
				thinLine.exists = curSection.exists;
				curSection.body.push(thinLine);
				sectionGroup.add(thinLine);
			}
			sectionList.push(curSection);
		}
	}

	function pushNote(note:Note)
	{
		note.setGraphicSize(CELL_SIZE, CELL_SIZE);
		note.updateHitbox();
		note.exists = false;
		noteGroup.add(note);

		if (note.sustainLength > 0)
		{
			var holdNote:SustainNote = {
				holdLength: note.sustainLength,
				tail: new FlxTypedSpriteGroup<FlxTiledSprite>(),
				exists: false
			};

			var resize:Float = (CELL_SIZE / SEPARATION);

			var hold:FlxTiledSprite = new FlxTiledSprite(Cache.get('tail${note.noteData}-BODY', GRAPHIC), CELL_SIZE, CELL_SIZE * note.sustainLength);
			hold.width = hold.graphic.width * resize;
			hold.scale.set(resize, CELL_SIZE);
			hold.exists = false;
			holdGroup.add(holdNote.tail.insert(0, hold));

			var end:FlxTiledSprite = new FlxTiledSprite(Cache.get('tail${note.noteData}-END', GRAPHIC), CELL_SIZE, CELL_SIZE);
			end.width = end.graphic.width * resize;
			end.height = end.graphic.height * resize;
			end.scale.set(resize, resize);
			end.exists = false;
			holdGroup.add(holdNote.tail.insert(1, end));

			holdMap.set(note, holdNote);
		}
	}

	// Just sum update functions for uh debugging and clean code??
	private function updateCrochet()
	{
		_conductorCrochet.y = getYFromStep(Conductor.step) + (CELL_SIZE * 0.5);
		receptors.y = _conductorCrochet.y;
	}

	private function updateSections()
	{
		for (i in 0...sectionList.length)
		{
			var curSection:Section = sectionList.unsafeGet(i);
			var time:Float = curSection.time;

			if (getYFromStep(time) <= camera.scroll.y + camera.height && !curSection.exists)
			{
				curSection.exists = true;

				curSection.header.exists = curSection.exists;
				for (j in 0...curSection.body.length)
					curSection.body[j].exists = curSection.exists;

				var displacement:Float = getYFromStep(time);
				curSection.header.setPosition(_boardPattern.x + _boardPattern.width / 2 - curSection.header.width / 2, _boardPattern.y + displacement);
				curSection.header.active = false;

				for (j in 0...curSection.body.length)
				{
					var segment = curSection.body[j];
					segment.setPosition(_boardPattern.x + _boardPattern.width / 2 - segment.width / 2, _boardPattern.y + getYFromStep(time + ((j + 1) * 4)));
					segment.active = false;
				}
			}

			if (getYFromStep(time) <= camera.scroll.y - camera.height && curSection.exists)
			{
				if (curSection.header.y <= camera.scroll.y - camera.height && curSection.header.exists)
					curSection.header.exists = false;

				for (j in 0...curSection.body.length)
				{
					var bodyLine:FlxSprite = curSection.body[j];
					if (bodyLine.y <= camera.scroll.y - camera.height && bodyLine.exists)
						bodyLine.exists = false;
				}
			}
		}
	}

	private function updateNotes()
	{
		for (note in noteGroup)
		{
			if (note == null)
				break;

			if (getYFromStep(note.stepTime) <= camera.scroll.y + camera.height && !note.isVisible)
				note.isVisible = true;

			if (getYFromStep(note.stepTime) <= camera.scroll.y - camera.height && note.isVisible)
			{
				note.isVisible = false;
				if (!note.isSustain) // do not clean if baddie is a bussy (it will break the whole thing)
					destroyNote(note);
			}

			// Input shit (gotta improve it??)

			// Note is above the crochet by half cell
			if (getYFromStep(note.stepTime) + (note.height + (CELL_SIZE * 0.5)) <= _conductorCrochet.y)
			{
				note.tooLate = true;
				note.canBeHit = false;
				note.alpha = 0.3;

				if (note.isSustain)
					holdMap.get(note).tail.alpha = 0.3;
			}
			// Note is below the crochet
			else
			{
				if ((note.strumTime * scrollSpeed) > (Conductor.time * scrollSpeed) - 166
					&& (note.strumTime * scrollSpeed) < (Conductor.time * scrollSpeed) + 166)
					note.canBeHit = true;
			}

			note.exists = note.isVisible;
			note.active = false;
			note.x = _boardPattern.x + note.noteData * CELL_SIZE;
			note.y = getYFromStep(note.stepTime); // make it that when holding the sustain it stops moving or sets the y position to a fixed one which would be the strums y position

			if (botPlay)
			{
				// dont destroy if baddie is a sussy :flushed:
				if ((_conductorCrochet.y >= note.y && _conductorCrochet.y <= note.y + note.height) && (note.sustainLength <= 0))
				{
					// cuz uhhhh botplay right
					receptors.members.unsafeGet(note.noteData).playAnim('confirm', true);
					destroyNote(note);
				}
			}
		}

		for (note => curHold in holdMap)
		{
			if (note == null)
				break;

			if (getYFromStep(note.stepTime) <= camera.scroll.y + camera.height && !curHold.exists)
				curHold.exists = true;

			// manage lifetime manually on sustain updating
			if (getYFromStep(note.stepTime + curHold.holdLength) <= camera.scroll.y - camera.height && curHold.exists)
			{
				curHold.exists = false;
				destroyNote(note);
			}

			curHold.tail.exists = curHold.exists;
			curHold.tail.active = false;

			curHold.tail.x = _boardPattern.x + note.noteData * CELL_SIZE + (note.width / 2 - curHold.tail.width / 2);
			curHold.tail.y = getYFromStep(note.stepTime) + CELL_SIZE / 2;
			curHold.tail.height = (((CELL_SIZE * curHold.holdLength) * scrollSpeed) - (CELL_SIZE * (1 - scrollSpeed)));

			if (botPlay)
			{
				if (_conductorCrochet.y >= curHold.tail.y && _conductorCrochet.y <= curHold.tail.y + curHold.tail.height)
				{
					receptors.members.unsafeGet(note.noteData).playAnim('confirm', true);
				}
			}
		}

		if (botPlay)
		{
			for (receptor in receptors)
			{
				if (receptor.animation.finished)
					receptor.playAnim('static');
			}
		}
	}

	private function updateCamFollow()
	{
		_camFollow.screenCenter(X);
		_camFollow.y = _conductorCrochet.y + (CELL_SIZE * CELL_OFFSET);

		camera.follow(_camFollow, LOCKON);
	}

	// I failed to strum time :pensive:
	private inline function getYFromStep(step:Float):Float
		return step * CELL_SIZE * scrollSpeed;

	public function destroyNote(note:Note)
	{
		note.exists = false;
		note.kill();

		noteGroup.remove(note, true);
		if (note.isSustain)
		{
			var curHold:SustainNote = holdMap.get(note);
			curHold.exists = false;
			curHold.tail.kill();

			holdGroup.remove(curHold.tail.members[0], true); // 0 them body
			holdGroup.remove(curHold.tail.members[1], true); // 1 its tail :smiling_imp:
			curHold.tail.destroy();

			holdMap.remove(note);
		}
		note.destroy();
	}
}
