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

typedef CharterSection =
{
	var header:FlxSprite;
	var numbers:Array<FlxText>;
	var body:Array<FlxSprite>;
}

typedef CharterNote =
{
	var holdLength:Float;
	var hold:FlxTiledSprite;
	var end:FlxTiledSprite;
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
	static final CELL_SIZE:Int = 80;
	static final keyAmount:Int = 4;
	static final swagWidth:Float = 160 * (CELL_SIZE / 160);

	/**
	 * How many tiles is the camera ahead of the crochet
	 */
	static var CELL_OFFSET:Float = 3.75;

	// Useful shit right here guys
	var noteGraphics(default, null):Map<NoteGraphicType, Array<FlxGraphic>> = [TAIL_BODY => [], TAIL_END => []];

	// shit receptors
	var receptors(default, null):FlxTypedSpriteGroup<Receptor>;

	// uhhh notes that need to be rendered????
	var noteGroup(default, null):Map<Note, CharterNote> = [];

	// SECTIONS LESGOO
	var sectionGroup:FlxTypedSpriteGroup<FlxSprite>;

	var sectionsList:Array<CharterSection> = [];

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
		for (i in 0...keyAmount)
		{
			var receptor:Receptor = new Receptor(0, 0, i);
			receptor.ID = i;

			receptor.setGraphicSize(Std.int((receptor.width / 0.7) * (CELL_SIZE / 160)));
			receptor.updateHitbox();

			receptor.x -= ((keyAmount / 2) * swagWidth);
			receptor.x += (swagWidth * i);

			receptor.playAnim('static');
			receptors.add(receptor);
		}
		add(receptors);
	}

	override function update(elapsed:Float)
	{
		_boardPattern.height = ((FlxG.sound.music.length / ScrollTest.Conductor.stepCrochet) * CELL_SIZE);

		super.update(elapsed);

		updateCrochet();
		updateSections();
		updateCamFollow();
	}

	private function cacheGraphics()
	{
		@:privateAccess
		_checkerboard = FlxGraphic.fromBitmapData(Cache.set(FlxGridOverlay.createGrid(CELL_SIZE, CELL_SIZE, CELL_SIZE * 2, CELL_SIZE * 2, true,
			FlxColor.WHITE, FlxColor.BLACK), BITMAP, 'board$CELL_SIZE'));
		_checkerboard.bitmap.colorTransform(new openfl.geom.Rectangle(0, 0, CELL_SIZE * 2, CELL_SIZE * 2), new openfl.geom.ColorTransform(1, 1, 1, 0.20));

		_line = Cache.set(FlxG.bitmap.create(CELL_SIZE * keyAmount, 1, FlxColor.WHITE), GRAPHIC, 'chartline');
		_sectionLine = Cache.set(FlxG.bitmap.create((CELL_SIZE * keyAmount) + 8, 2, FlxColor.WHITE), GRAPHIC, 'sectionline');

		for (i in 0...keyAmount)
		{
			var noteHold:Note = new Note(0, i, null, true);
			var noteEnd:Note = new Note(0, i, noteHold, true);

			var frameB:FlxFrame = noteHold.frames.framesHash.get(noteHold.animation.frameName);
			var graphicB:FlxGraphic = FlxGraphic.fromFrame(frameB);
			noteGraphics.get(TAIL_BODY).push(graphicB);

			var frameE:FlxFrame = noteEnd.frames.framesHash.get(noteEnd.animation.frameName);
			var graphicE:FlxGraphic = FlxGraphic.fromFrame(frameE);
			noteGraphics.get(TAIL_END).push(graphicE);

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

			var curSection:CharterSection = {header: lineSprite, body: [], numbers: []};

			// Section indicator
			for (j in 0...2)
			{
				var sectionNumbers:FlxText = new FlxText().setFormat(Cache.getFont('vcr.ttf'), 16, FlxColor.WHITE);
				sectionNumbers.alpha = 0.45;
				sectionNumbers.exists = lineSprite.exists;
				curSection.numbers.push(sectionNumbers);
				sectionGroup.add(sectionNumbers);
			}

			// Section body lines
			for (j in 1...4)
			{
				var thinLine:FlxSprite = new FlxSprite(0, 0, _line);
				thinLine.alpha = 0.75;
				thinLine.exists = lineSprite.exists;
				curSection.body.push(thinLine);
				sectionGroup.add(thinLine);
			}
			sectionsList.push(curSection);
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
		for (i in 0...sectionsList.length)
		{
			var curSection:CharterSection = sectionsList[i];

			if (getYFromStep(i * 16) <= camera.scroll.y - camera.height && curSection.header.exists)
			{
				trace('out of bounds');
				curSection.header.exists = false;
				curSection.numbers[0].exists = false;
				curSection.numbers[1].exists = false;
				for (j in 0...curSection.body.length)
					curSection.body[j].exists = false;
			}

			if (getYFromStep(i * 16) >= camera.scroll.y + camera.height && !curSection.header.exists)
			{
				trace('displaying at $i ${ScrollTest.Conductor.step}');
				var displacement:Float = getYFromStep(i * 16);
				curSection.header.setPosition(_boardPattern.x + _boardPattern.width / 2 - curSection.header.width / 2, _boardPattern.y + displacement);
				curSection.header.exists = true;
				curSection.header.active = false;

				curSection.numbers[0].text = '$i';
				curSection.numbers[0].setPosition(curSection.header.x - curSection.numbers[0].width - 8,
					curSection.header.y - curSection.numbers[0].height / 2);
				curSection.numbers[0].exists = curSection.header.exists;
				curSection.numbers[0].active = curSection.header.active;
				curSection.numbers[1].text = '$i';
				curSection.numbers[1].setPosition(curSection.header.x + curSection.header.width + 8, curSection.header.y - curSection.numbers[0].height / 2);
				curSection.numbers[1].exists = curSection.header.exists;
				curSection.numbers[1].active = curSection.header.active;

				for (j in 0...curSection.body.length)
				{
					var segment = curSection.body[j];
					segment.setPosition(_boardPattern.x + _boardPattern.width / 2 - segment.width / 2, _boardPattern.y + getYFromStep(i * 16 + ((j + 1) * 4)));
					segment.exists = curSection.header.exists;
					segment.active = curSection.header.active;
				}
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
}
