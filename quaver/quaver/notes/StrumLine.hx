package quaver.notes;

import backend.Cache;
import backend.Conductor;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
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
class StrumLine extends FlxSpriteGroup
{
	static final CELL_SIZE:Int = 70;
	static final keyAmount:Int = 4;
	static final swagWidth:Float = 160 * (CELL_SIZE / 160);

	var noteGraphics(default, null):Map<NoteGraphicType, Array<FlxGraphic>> = [TAIL_BODY => [], TAIL_END => []];

	var receptors(default, null):FlxTypedSpriteGroup<Receptor>;
	var noteGroup(default, null):Map<Note, CharterNote> = [];

	private var _checkerboard(default, null):FlxGraphic;
	private var _line(default, null):FlxGraphic;
	private var _sectionLine(default, null):FlxGraphic;

	private var _boardPattern(default, null):FlxTiledSprite;
	private var _conductorCrochet(default, null):FlxSprite;

	var camScroll:FlxCamera;

	function new(X:Float = 0, Y:Float = 0)
	{
		super(X, Y);

		camScroll = new FlxCamera();
		camScroll.bgColor.alpha = 0;
		FlxG.cameras.add(camScroll);

		cameras = [camScroll];

		cacheGraphics();

		_boardPattern = new FlxTiledSprite(_checkerboard, CELL_SIZE * keyAmount, CELL_SIZE * 16);
		_boardPattern.setPosition(0, 0);
		_boardPattern.x -= ((keyAmount / 2) * swagWidth);
		_boardPattern.active = false;
		add(_boardPattern);

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

		_conductorCrochet.y = ((ScrollTest.Conductor.time / ScrollTest.Conductor.stepCrochet) + (CELL_SIZE * 0.5)) * CELL_SIZE;
		receptors.y = _conductorCrochet.y - (CELL_SIZE * 0.5);

		camScroll.y = FlxMath.lerp(_conductorCrochet.y + (CELL_SIZE * 4), camScroll.y, FlxMath.bound(1 - (elapsed * 3.125), 0, 1));

		super.update(elapsed);
	}

	private function cacheGraphics()
	{
		@:privateAccess
		_checkerboard = new FlxGraphic('board$CELL_SIZE',
			FlxGridOverlay.createGrid(CELL_SIZE, CELL_SIZE, CELL_SIZE * 2, CELL_SIZE * 2, true, FlxColor.WHITE, FlxColor.BLACK), true);
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
}
