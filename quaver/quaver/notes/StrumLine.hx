package quaver.notes;

import backend.Cache;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import states.ScrollTest;

using backend.Extensions;

typedef Section =
{
	var header:FlxSprite;
	var body:Array<FlxSprite>;
	var exists:Bool;
}

typedef SustainNote =
{
	var holdLength:Float;
	var hold:FlxTiledSprite;
	var end:FlxTiledSprite;
	var exists:Bool;
}

enum NoteGraphicType
{
	TAIL_BODY;
	TAIL_END;
}

@:publicFields
// NOTE: Apparently when parsing notes, making sustains isn't actually needed as this will create the FlxTiledSprite and scale it to match the sustain length when pushed
// TODO: Events
class StrumLine extends FlxSpriteGroup
{
	static final SEPARATION:Int = 160;
	static final CELL_SIZE:Int = 90;
	static final keyAmount:Int = 4;
	static final swagWidth:Float = SEPARATION * (CELL_SIZE / SEPARATION);

	/**
	 * How many tiles is the camera ahead of the crochet
	 */
	static var CELL_OFFSET:Float = 3.75;

	// Cache graphics, bg and camera
	private var noteGraphics(default, null):Map<NoteGraphicType, Array<FlxGraphic>> = [TAIL_BODY => [], TAIL_END => []];
	private var _checkerboard(default, null):FlxGraphic;
	private var _line(default, null):FlxGraphic;
	private var _sectionLine(default, null):FlxGraphic;

	private var _boardPattern(default, null):FlxTiledSprite;
	private var _conductorCrochet(default, null):FlxSprite;

	private var _camFollow:FlxObject;

	// Exposed variables
	var botPlay:Bool = false;

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
		_boardPattern.height = ((FlxG.sound.music.length / ScrollTest.Conductor.stepCrochet) * CELL_SIZE);

		super.update(elapsed);

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
		_checkerboard.bitmap.colorTransform(new openfl.geom.Rectangle(0, 0, CELL_SIZE * 2, CELL_SIZE * 2), new openfl.geom.ColorTransform(1, 1, 1, 0));

		_sectionLine = Cache.set(FlxG.bitmap.create((CELL_SIZE * keyAmount) + 30, 5, FlxColor.WHITE), GRAPHIC, 'sectionline');
		_line = Cache.set(FlxG.bitmap.create((CELL_SIZE * keyAmount) + 20, 2, FlxColor.WHITE), GRAPHIC, 'chartline');

		for (i in 0...keyAmount)
		{
			var noteHold:Note = new Note(0, i, null, true);
			var noteEnd:Note = new Note(0, i, noteHold, true);

			var frameB:FlxFrame = noteHold.frames.framesHash.get(noteHold.animation.frameName);
			var graphicB:FlxGraphic = FlxGraphic.fromFrame(frameB);
			noteGraphics.get(TAIL_BODY).insert(i, graphicB);

			var frameE:FlxFrame = noteEnd.frames.framesHash.get(noteEnd.animation.frameName);
			var graphicE:FlxGraphic = FlxGraphic.fromFrame(frameE);
			noteGraphics.get(TAIL_END).insert(i, graphicE);

			noteEnd.destroy();
			noteHold.destroy();
		}
	}

	public function regenSections()
	{
		for (i in sectionGroup)
			i.destroy();

		sectionGroup.clear();

		for (i in 0...Std.int((FlxG.sound.music.length / ScrollTest.Conductor.stepCrochet) / 16))
		{
			// Them header
			var lineSprite:FlxSprite = new FlxSprite(0, 0, _sectionLine);
			lineSprite.alpha = 0.5;
			lineSprite.exists = false;
			sectionGroup.add(lineSprite);

			var curSection:Section = {
				header: lineSprite,
				body: [],
				exists: lineSprite.exists
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
			var resize:Float = (CELL_SIZE / SEPARATION);

			var hold:FlxTiledSprite = new FlxTiledSprite(noteGraphics.get(TAIL_BODY)[note.noteData], CELL_SIZE, CELL_SIZE * note.sustainLength);
			hold.width = hold.graphic.width * resize;
			hold.scale.set(resize, CELL_SIZE);
			hold.exists = false;
			holdGroup.add(hold);

			var end:FlxTiledSprite = new FlxTiledSprite(noteGraphics.get(TAIL_END)[note.noteData], CELL_SIZE, CELL_SIZE);
			end.width = end.graphic.width * resize;
			end.height = end.graphic.height * resize;
			end.scale.set(resize, resize);
			end.exists = false;
			holdGroup.add(end);

			holdMap.set(note, {
				holdLength: note.sustainLength,
				hold: hold,
				end: end,
				exists: false
			});
		}
	}

	// Just sum update functions for uh debugging and clean code??
	private function updateCrochet()
	{
		_conductorCrochet.y = getYFromStep(ScrollTest.Conductor.step) + (CELL_SIZE * 0.5);
		receptors.y = _conductorCrochet.y;
	}

	// TODO: Proper space check and shit though I believe this is already optimized
	private function updateSections()
	{
		for (i in 0...sectionList.length)
		{
			var curSection:Section = sectionList[i];

			if (getYFromStep(i * 16) <= camera.scroll.y + camera.height && !curSection.exists)
			{
				curSection.exists = true;

				curSection.header.exists = curSection.exists;
				for (j in 0...curSection.body.length)
					curSection.body[j].exists = curSection.exists;

				var displacement:Float = getYFromStep(i * 16);
				curSection.header.setPosition(_boardPattern.x + _boardPattern.width / 2 - curSection.header.width / 2, _boardPattern.y + displacement);
				curSection.header.active = false;

				for (j in 0...curSection.body.length)
				{
					var segment = curSection.body[j];
					segment.setPosition(_boardPattern.x + _boardPattern.width / 2 - segment.width / 2, _boardPattern.y + getYFromStep(i * 16 + ((j + 1) * 4)));
					segment.active = false;
				}
			}

			if (getYFromStep(i * 16) <= camera.scroll.y - camera.height && curSection.exists)
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
				note.isVisible = false;

			// Input shit

			// Note is above the crochet by half cell
			if (getYFromStep(note.stepTime) + (note.height + (CELL_SIZE * 0.5)) <= _conductorCrochet.y)
			{
				note.tooLate = true;
				note.canBeHit = false;
				note.alpha = 0.3;

				if (note.sustainLength > 0)
				{
					var curHold:SustainNote = holdMap.get(note);
					curHold.hold.alpha = 0.3;
					curHold.end.alpha = 0.3;
				}
			}
			// Note is below the crochet
			else
			{
				if (note.strumTime > ScrollTest.Conductor.time - 166 && note.strumTime < ScrollTest.Conductor.time + 166)
					note.canBeHit = true;
				// strumTime > ScrollTest.Conductor.time - 166 && strumTime < ScrollTest.Conductor.time + (166 * 0.5)
			}

			note.exists = note.isVisible;
			note.active = false;
			note.x = _boardPattern.x + note.noteData * CELL_SIZE;
			note.y = getYFromStep(note.stepTime);

			if (botPlay)
			{
				if (_conductorCrochet.y >= note.y && _conductorCrochet.y <= note.y + note.height)
				{
					// cuz uhhhh botplay right
					receptors.members[note.noteData].playAnim('confirm', true);
					destroyNote(note);
				}
			}
		}

		for (note in holdMap.keys())
		{
			if (note == null)
				break;

			var curHold:SustainNote = holdMap.get(note);

			if (getYFromStep(note.stepTime) <= camera.scroll.y + camera.height && !curHold.exists)
				curHold.exists = true;

			if (getYFromStep(note.stepTime + curHold.holdLength) <= camera.scroll.y - camera.height && curHold.exists)
				curHold.exists = false;

			curHold.hold.exists = curHold.end.exists = curHold.exists;
			curHold.hold.active = curHold.end.active = false;

			curHold.hold.x = _boardPattern.x + note.noteData * CELL_SIZE + (note.width / 2 - curHold.hold.width / 2);
			curHold.hold.y = getYFromStep(note.stepTime) + CELL_SIZE / 2;
			curHold.hold.height = ((CELL_SIZE * curHold.holdLength) - CELL_SIZE);

			curHold.end.x = _boardPattern.x + note.noteData * CELL_SIZE + (note.width / 2 - curHold.end.width / 2);
			curHold.end.y = curHold.hold.y + curHold.hold.height;

			if (botPlay)
			{
				if (_conductorCrochet.y >= curHold.hold.y
					&& _conductorCrochet.y <= curHold.hold.y + curHold.hold.height + curHold.end.height)
					receptors.members.unsafeGet(note.noteData).playAnim('confirm', true);
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
		return step * CELL_SIZE;

	public function destroyNote(note:Note)
	{
		note.exists = false;

		note.kill();

		(note.isSustain ? holdGroup.remove(note, true) : noteGroup.remove(note, true));

		if (note.head != null)
		{
			if (note.head.tail.contains(note))
				note.head.tail.remove(note);
		}

		note.destroy();
	}
}
