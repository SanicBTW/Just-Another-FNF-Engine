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
import flixel.text.FlxText;
import flixel.util.FlxColor;
import states.ScrollTest;

typedef Section =
{
	var header:FlxSprite;
	var numbers:Array<FlxText>;
	var body:Array<FlxSprite>;
	var printed:Bool;
	var exists:Bool;
}

typedef CharterNote =
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
// OK So instead of creating a camera in here and manipulate it and shit, use a dedicated camera (required to avoid any other bullshit issue) assigned on .cameras when creating it and using it somewhere else
class StrumLine extends FlxSpriteGroup
{
	static final SEPARATION:Int = 160;
	static final CELL_SIZE:Int = 80;
	static final keyAmount:Int = 4;
	static final swagWidth:Float = SEPARATION * (CELL_SIZE / SEPARATION);

	/**
	 * How many tiles is the camera ahead of the crochet
	 */
	static var CELL_OFFSET:Float = 3.75;

	// Useful shit right here guys
	var noteGraphics(default, null):Map<NoteGraphicType, Array<FlxGraphic>> = [TAIL_BODY => [], TAIL_END => []];

	// shit receptors
	var receptors(default, null):FlxTypedSpriteGroup<Receptor>;
	var noteGroup(default, null):FlxTypedSpriteGroup<Note>;
	var holdGroup(default, null):FlxTypedSpriteGroup<FlxSprite>;

	var holdMap(default, null):Map<Note, CharterNote> = [];

	// SECTIONS LESGOO
	var sectionGroup:FlxTypedSpriteGroup<FlxSprite>;
	var sectionList:Array<Section> = [];

	// Background shit and grid rendering I guess
	private var _checkerboard(default, null):FlxGraphic;
	private var _line(default, null):FlxGraphic;
	private var _sectionLine(default, null):FlxGraphic;

	private var _boardPattern(default, null):FlxTiledSprite;
	private var _conductorCrochet(default, null):FlxSprite;

	private var _camFollow:FlxObject;

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
		_checkerboard.bitmap.colorTransform(new openfl.geom.Rectangle(0, 0, CELL_SIZE * 2, CELL_SIZE * 2), new openfl.geom.ColorTransform(1, 1, 1, 0.20));

		_sectionLine = Cache.set(FlxG.bitmap.create((CELL_SIZE * keyAmount) + 20, 2, FlxColor.WHITE), GRAPHIC, 'sectionline');
		_line = Cache.set(FlxG.bitmap.create((CELL_SIZE * keyAmount) + 14, 1, FlxColor.WHITE), GRAPHIC, 'chartline');

		for (i in 0...keyAmount)
		{
			var noteHold:Note = new Note(0, i, null, true);
			noteHold.generate();
			var noteEnd:Note = new Note(0, i, noteHold, true);
			noteEnd.generate();

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

	private function regenSections()
	{
		for (i in sectionGroup)
			i.destroy();

		sectionGroup.clear();

		// TODO: get amount of sections possible on bpm changes and show the correct timing
		// like if there are bpm changes and uh like the section lines are more near and shit like that, just copy osu dunno
		// or even better, just dont implement it !!!!

		for (i in 0...Std.int((FlxG.sound.music.length / ScrollTest.Conductor.stepCrochet) / 16))
		{
			// Them header
			var lineSprite:FlxSprite = new FlxSprite(0, 0, _sectionLine);
			lineSprite.alpha = 0.45;
			lineSprite.exists = false;
			sectionGroup.add(lineSprite);

			// TODO: add notes to the section instead of pushing them randomly without knowing section and that shit i dont know what im writing lol

			var curSection:Section = {
				header: lineSprite,
				body: [],
				numbers: [],
				printed: false,
				exists: lineSprite.exists
			};

			// Section indicator
			for (j in 0...2)
			{
				var sectionNumbers:FlxText = new FlxText().setFormat(Cache.getFont('vcr.ttf'), 16, FlxColor.WHITE);
				sectionNumbers.alpha = 0.45;
				sectionNumbers.exists = curSection.exists;
				curSection.numbers.push(sectionNumbers);
				sectionGroup.add(sectionNumbers);
			}

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
		if (note.generated)
			return;

		note.generate();
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
		receptors.y = _conductorCrochet.y - (CELL_SIZE * 0.5);
	}

	// TODO: Proper space check and shit though I believe this is already optimized
	private function updateSections()
	{
		for (i in 0...sectionList.length)
		{
			var curSection:Section = sectionList[i];

			if (getYFromStep(i * 16) <= camera.scroll.y + camera.height && !curSection.exists)
			{
				if (!curSection.printed)
				{
					trace('Showing section $i at ${ScrollTest.Conductor.step}');
					curSection.printed = true;
				}
				curSection.exists = true;
			}

			if (getYFromStep(i * 16) <= camera.scroll.y - camera.height && curSection.exists)
				curSection.exists = false;

			curSection.header.exists = curSection.exists;
			curSection.numbers[0].exists = curSection.exists;
			curSection.numbers[1].exists = curSection.exists;
			for (j in 0...curSection.body.length)
				curSection.body[j].exists = curSection.exists;

			if (curSection.exists)
			{
				var displacement:Float = getYFromStep(i * 16);
				curSection.header.setPosition(_boardPattern.x + _boardPattern.width / 2 - curSection.header.width / 2, _boardPattern.y + displacement);
				curSection.header.active = false;

				curSection.numbers[0].text = '$i';
				curSection.numbers[0].setPosition(curSection.header.x - curSection.numbers[0].width - 8,
					curSection.header.y - curSection.numbers[0].height / 2);
				curSection.numbers[0].active = false;

				curSection.numbers[1].text = '$i';
				curSection.numbers[1].setPosition(curSection.header.x + curSection.header.width + 8, curSection.header.y - curSection.numbers[0].height / 2);
				curSection.numbers[1].active = false;

				for (j in 0...curSection.body.length)
				{
					var segment = curSection.body[j];
					segment.setPosition(_boardPattern.x + _boardPattern.width / 2 - segment.width / 2, _boardPattern.y + getYFromStep(i * 16 + ((j + 1) * 4)));
					segment.active = false;
				}
			}
		}
	}

	private function updateNotes()
	{
		for (note in noteGroup)
		{
			if (!note.generated || note == null)
				break;

			if (getYFromStep(note.stepTime) <= camera.scroll.y + camera.height && !note.isVisible)
				note.isVisible = true;

			if (getYFromStep(note.stepTime) <= camera.scroll.y - camera.height && note.isVisible)
				note.isVisible = false;

			note.exists = note.isVisible;
			note.x = _boardPattern.x + note.noteData * CELL_SIZE;
			note.y = getYFromStep(note.stepTime);
		}

		for (note in holdMap.keys())
		{
			if (!note.generated || note == null)
				break;

			var curHold:CharterNote = holdMap.get(note);

			if (getYFromStep(note.stepTime + curHold.holdLength) <= camera.scroll.y + camera.height && !curHold.exists)
				curHold.exists = true;

			if (getYFromStep(note.stepTime + curHold.holdLength) <= camera.scroll.y - camera.height && curHold.exists)
				curHold.exists = false;

			curHold.hold.exists = curHold.exists;
			curHold.end.exists = curHold.exists;

			curHold.hold.x = _boardPattern.x + note.noteData * CELL_SIZE + (note.width / 2 - curHold.hold.width / 2);
			curHold.hold.y = getYFromStep(note.stepTime) + CELL_SIZE / 2;

			curHold.hold.height = ((CELL_SIZE * curHold.holdLength) - CELL_SIZE);

			curHold.end.x = _boardPattern.x + note.noteData * CELL_SIZE + (note.width / 2 - curHold.end.width / 2);
			curHold.end.y = curHold.hold.y + curHold.hold.height;
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
}
