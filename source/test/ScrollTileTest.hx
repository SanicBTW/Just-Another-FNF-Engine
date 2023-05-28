package test;

import backend.Controls.Action;
import base.Conductor;
import base.MusicBeatState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import funkin.ChartLoader;
import funkin.SongTools.SongData;
import funkin.SongTools;
import funkin.notes.Note;
import funkin.notes.Receptor.ReceptorData;
import funkin.notes.StrumLine;
import network.MultiCallback;
import network.pocketbase.Collection;
import network.pocketbase.PBRequest;
import network.pocketbase.Record.FunkinRecord;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import openfl.media.Sound;

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

// https://github.com/SanicBTW/Scarlet-Melopoeia-Port/blob/master/source/ChartingState.hx#L1388
// https://github.com/SanicBTW/Forever-Engine-Archive/blob/rewrite/source/states/editors/ChartEditor.hx
// https://github.com/SanicBTW/FNF-PsychEngine-0.3.2h/blob/6f1ce5b990fc9a332c654828f4813dd7370b9765/source/MainWorker.hx
// Once i understand this i will properly rewrite it
// TODO: add pooling, once working add threads natively and html5
class ScrollTileTest extends MusicBeatState
{
	var cellSize:Int = 70;
	var keyAmount:Int = 4;
	var strumlines:Int = 2;
	var chartZoom:Float = 1;
	var targetDCamera:Float = 1;

	var totalElapsed:Float = 0;
	var lastTiming:Float = 0;

	var curSection:Int = 0;
	var lastSection:Int = 0;

	var chartCamera:FlxCamera;
	var chartHUD:FlxCamera;

	var camObject:FlxObject;

	var checkerboard:FlxGraphic;
	var line:FlxGraphic;
	var sectionLine:FlxGraphic;
	var conductorCrochet:FlxSprite;
	var gridBackground:FlxTiledSprite;
	var boardPattern:FlxTiledSprite;

	var receptorGroup:FlxTypedGroup<StrumLine>;

	var sectionGroup:FlxTypedGroup<FlxSprite>;
	var sectionsList:Array<CharterSection> = [];

	var holdGraphics:Array<FlxGraphic> = [];
	var holdEnds:Array<FlxGraphic> = [];
	var holdsGroup:FlxTypedGroup<FlxSprite>;
	var holdsMap:Map<Note, CharterNote> = [];

	var notesGroup:FlxTypedGroup<Note>;

	#if !html5
	var noteMutex:sys.thread.Mutex = new sys.thread.Mutex();
	#end

	// tried doing the FlxG.cameras.setDefaultDrawTarget but broke everything so moved to the old one
	override public function create()
	{
		super.create();

		chartCamera = new FlxCamera();
		FlxG.cameras.reset(chartCamera);
		FlxCamera.defaultCameras = [chartCamera];

		chartHUD = new FlxCamera();
		chartHUD.bgColor.alpha = 0;
		FlxG.cameras.add(chartHUD);

		generateBackground();
		loadSong();

		FlxG.mouse.visible = true;
		FlxG.mouse.useSystemCursor = true;
	}

	// will pick a random one or smth - default will be rolling
	// wacky code
	function loadSong()
	{
		var endChart:String = '';
		var endInst:Sound = new Sound();
		var endVoices:Null<Sound> = null;

		var netCb:MultiCallback = new MultiCallback(() ->
		{
			ChartLoader.loadNetChart(endChart, endInst, endVoices);

			regenSections();
			initHoldSprites();
			regenNotes();
		});

		PBRequest.getRecords('funkin', (funky:Collection<FunkinRecord>) ->
		{
			var selected:FunkinRecord = {
				id: 'z4q1mxwjtkuy2ag',
				collectionId: '9id75c79c70m6yq',
				collectionName: 'funkin',
				created: '2023-04-18 19:57:08.410Z',
				updated: '2023-04-18 19:57:08.410Z',
				song: 'rolling',
				chart: 'rolling_hard_pd9D29K3tR.json',
				inst: 'inst_1_GpoqrnN968.ogg',
				voices: 'voices_HHCKIaUpav.ogg'
			};

			selected = funky.items[FlxG.random.int(0, funky.totalItems)];

			var chartCb:() -> Void = netCb.add("chart:" + selected.id);
			var instCb:() -> Void = netCb.add("inst:" + selected.id);
			var voicesCb:() -> Void = netCb.add("voices:" + selected.id);

			PBRequest.getFile(selected, 'chart', (chart:String) ->
			{
				endChart = chart;
				trace('finished loading chart');
				chartCb();

				PBRequest.getFile(selected, 'inst', (inst:Sound) ->
				{
					endInst = inst;
					trace('finished loading inst');
					instCb();

					if (selected.voices != '')
					{
						PBRequest.getFile(selected, 'voices', (voices:Sound) ->
						{
							endVoices = voices;
							trace('finished loading voices');
							voicesCb();
						}, SOUND);
					}
					else
						voicesCb();
				}, SOUND);
			}, RAW_STRING);
		});
	}

	function generateBackground()
	{
		gridBackground = new FlxTiledSprite(Paths.image('chart/gridPurple'), FlxG.width, FlxG.height);
		gridBackground.cameras = [chartCamera];
		add(gridBackground);

		var background:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			[FlxColor.fromRGB(167, 103, 225), FlxColor.fromRGB(137, 20, 181)]);
		background.alpha = 0.6;
		background.cameras = [chartCamera];
		add(background);

		// dark background
		var darkBackground:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		darkBackground.setGraphicSize(Std.int(FlxG.width));
		darkBackground.cameras = [chartCamera];
		darkBackground.scrollFactor.set();
		darkBackground.screenCenter();
		darkBackground.alpha = 0.7;
		add(darkBackground);

		// dark background
		var funkyBack:FlxSprite = new FlxSprite().loadGraphic(Paths.image('chart/bg'));
		funkyBack.setGraphicSize(Std.int(FlxG.width));
		funkyBack.cameras = [chartCamera];
		funkyBack.scrollFactor.set();
		funkyBack.blend = BlendMode.DIFFERENCE;
		funkyBack.screenCenter();
		funkyBack.alpha = 0.07;
		add(funkyBack);

		@:privateAccess
		checkerboard = new FlxGraphic('board$cellSize',
			FlxGridOverlay.createGrid(cellSize, cellSize, cellSize * 2, cellSize * 2, true, FlxColor.WHITE, FlxColor.BLACK), true);
		checkerboard.bitmap.colorTransform(new Rectangle(0, 0, cellSize * 2, cellSize * 2), new ColorTransform(1, 1, 1, 0.20));

		line = FlxG.bitmap.create(cellSize * keyAmount * strumlines, 1, FlxColor.WHITE, true, 'chartline');
		sectionLine = FlxG.bitmap.create((cellSize * keyAmount * strumlines) + 8, 2, FlxColor.WHITE, true, 'sectionline');

		FlxCamera.defaultCameras = [chartHUD];

		boardPattern = new FlxTiledSprite(checkerboard, cellSize * keyAmount * strumlines, cellSize * 16);
		boardPattern.screenCenter(X);
		add(boardPattern);

		sectionGroup = new FlxTypedGroup<FlxSprite>();
		add(sectionGroup);

		holdsGroup = new FlxTypedGroup<FlxSprite>();
		add(holdsGroup);

		notesGroup = new FlxTypedGroup<Note>();
		add(notesGroup);

		conductorCrochet = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		conductorCrochet.setGraphicSize(Std.int((cellSize * keyAmount * strumlines) + cellSize), 2);
		conductorCrochet.screenCenter(X);
		conductorCrochet.y = cellSize / 2;
		add(conductorCrochet);

		receptorGroup = new FlxTypedGroup<StrumLine>();
		for (i in 0...strumlines)
		{
			var strumline:StrumLine = new StrumLine(boardPattern.x + ((cellSize * keyAmount) * i) + ((cellSize * keyAmount) / 2), (cellSize / 2) + 2,
				"default", (cellSize / 160));
			strumline.alpha = 0.75;
			receptorGroup.add(strumline);
		}
		add(receptorGroup);

		camObject = new FlxObject();
	}

	function initHoldSprites()
	{
		for (strumline in receptorGroup)
		{
			for (i in 0...strumline.receptors.members.length)
			{
				var noteHold:Note = new Note(0, i, strumline.receptors.members[i].noteType, i, null, true);
				var noteEnd:Note = new Note(0, i, strumline.receptors.members[i].noteType, i, noteHold, true);

				var frameH:FlxFrame = noteHold.frames.framesHash.get(noteHold.animation.frameName);
				var graphicH:FlxGraphic = FlxGraphic.fromFrame(frameH);
				holdGraphics.push(graphicH);

				var frameE:FlxFrame = noteEnd.frames.framesHash.get(noteEnd.animation.frameName);
				var graphicE:FlxGraphic = FlxGraphic.fromFrame(frameE);
				holdEnds.push(graphicE);

				noteEnd.destroy();
				noteHold.destroy();
			}
		}
	}

	function regenSections()
	{
		for (i in sectionGroup)
			i.destroy();
		sectionGroup.clear();

		for (i in 0...SONG.sections)
		{
			var lineSprite:FlxSprite = new FlxSprite(0, 0, sectionLine);
			lineSprite.active = false;
			lineSprite.alpha = 0.45;
			sectionGroup.add(lineSprite);
			var thisSection:CharterSection = {header: lineSprite, body: [], numbers: []};

			for (j in 0...2)
			{
				var sectionNumbers:FlxText = new FlxText().setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE);
				sectionNumbers.alpha = 0.45;
				sectionNumbers.active = lineSprite.active;
				thisSection.numbers.push(sectionNumbers);
				sectionGroup.add(sectionNumbers);
			}

			for (j in 1...4)
			{
				var thinLine:FlxSprite = new FlxSprite(0, 0, line);
				thinLine.alpha = 0.75;
				thinLine.active = lineSprite.active;
				thisSection.body.push(thinLine);
				sectionGroup.add(thinLine);
			}
			sectionsList.push(thisSection);
		}
	}

	function getPositionHorizontal(noteStrumline:Int, noteData:Int)
	{
		var returnPos:Int = 0;
		for (i in 0...noteStrumline + 1)
		{
			for (j in 0...receptorGroup.members[i].receptorData.keyAmount)
			{
				if (i == noteStrumline && j == noteData)
					return returnPos;
				returnPos++;
			}
		}
		return returnPos;
	}

	// goofy
	function regenNotes()
	{
		for (i in notesGroup)
			i.destroy();
		notesGroup.clear();

		noteMutex.acquire();
		for (qNote in ChartLoader.noteQueue)
		{
			var note:Note = new Note(qNote.strumTime, qNote.noteData, qNote.noteType, qNote.strumLine);
			note.setGraphicSize(cellSize, cellSize);
			note.updateHitbox();
			note.active = false;
			note.visible = false;
			notesGroup.add(note);

			if (qNote.sustainLength > 0)
			{
				// essentials
				var curIndex:Int = getPositionHorizontal(qNote.strumLine, qNote.noteData);
				var receptorData:ReceptorData = receptorGroup.members[qNote.strumLine].receptorData;
				var resize:Float = (cellSize / receptorData.separation);

				var hold:FlxTiledSprite = new FlxTiledSprite(holdGraphics[curIndex], cellSize, cellSize * qNote.sustainLength);
				hold.width = hold.graphic.width * resize;
				hold.scale.set(resize, cellSize);
				hold.active = false;
				hold.visible = false;
				holdsGroup.add(hold);

				var end:FlxTiledSprite = new FlxTiledSprite(holdEnds[curIndex], cellSize, cellSize);
				end.height = end.graphic.height * resize;
				end.width = end.graphic.width * resize;
				end.scale.set(resize, resize);
				end.active = false;
				end.visible = false;
				holdsGroup.add(end);

				holdsMap.set(note, {holdLength: qNote.sustainLength, hold: hold, end: end});
			}
		}
		noteMutex.release();
		trace('finished generating notes');
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.pressed.ALT)
		{
			if (FlxG.mouse.wheel != 0)
				targetDCamera += FlxG.mouse.wheel / 10;

			if (FlxG.mouse.justPressedMiddle)
				targetDCamera = chartZoom;

			FlxG.camera.zoom = FlxMath.lerp(targetDCamera, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 8.5), 0, 1));
		}

		super.update(elapsed);

		boardPattern.scale.y = chartZoom;
		boardPattern.height = ((Conductor.boundInst.length / Conductor.stepCrochet) * cellSize) * chartZoom;

		conductorCrochet.y = getYFromStep((Conductor.songPosition - sectionStartTime())) + (cellSize * 0.5);
		for (strumline in receptorGroup)
			strumline.y = conductorCrochet.y - (cellSize * 0.5);

		for (i in 0...sectionsList.length)
		{
			var mySection:CharterSection = sectionsList[i];
			if (getYFromStep(i * 16) <= chartHUD.scroll.y - chartHUD.height || getYFromStep(i * 16) >= chartHUD.scroll.y + chartHUD.height)
			{
				if (mySection.header.visible)
				{
					mySection.header.visible = false;
					mySection.numbers[0].visible = false;
					mySection.numbers[1].visible = false;
					for (j in 0...mySection.body.length)
						mySection.body[j].visible = false;
				}
			}
			var displacement:Float = getYFromStep(i * 16);
			mySection.header.setPosition(boardPattern.x + boardPattern.width / 2 - mySection.header.width / 2, boardPattern.y + displacement);
			mySection.header.visible = true;
			// numbers
			mySection.numbers[0].text = '$i';
			mySection.numbers[0].setPosition(mySection.header.x - mySection.numbers[0].width - 8, mySection.header.y - mySection.numbers[0].height / 2);
			mySection.numbers[0].visible = true;
			mySection.numbers[1].text = '$i';
			mySection.numbers[1].setPosition(mySection.header.x + mySection.header.width + 8, mySection.header.y - mySection.numbers[0].height / 2);
			mySection.numbers[1].visible = true;

			for (j in 0...mySection.body.length)
			{
				var segment = mySection.body[j];
				segment.setPosition(boardPattern.x + boardPattern.width / 2 - segment.width / 2, boardPattern.y + getYFromStep(i * 16 + ((j + 1) * 4)));
				segment.visible = true;
			}
		}

		/*
			if (noteMutex.tryAcquire())
			{
				for (daNote in notesGroup)
				{
					if (getYFromStep(daNote.stepTime) <= chartHUD.scroll.y - chartHUD.height
						|| getYFromStep(daNote.stepTime) >= chartHUD.scroll.y + chartHUD.height)
					{
						if (daNote != null)
							daNote.visible = false;
					}
					daNote.visible = true;
					daNote.x = boardPattern.x + getPositionHorizontal(daNote.strumLine, daNote.noteData) * cellSize;
					daNote.y = getYFromStep(daNote.stepTime);

					if (Conductor.boundInst.playing)
					{
						if ((daNote.stepTime * lastChange.stepCrochet) >= lastTiming
							&& (daNote.stepTime * lastChange.stepCrochet) <= Conductor.songPosition && lastTiming >= Conductor.songPosition)
						{
							trace('what');
							receptorGroup.members[daNote.strumLine].receptors.members[daNote.noteData].playAnim('confirm');
							lastTiming = Conductor.songPosition;
						}
					}
				}

				for (note in holdsMap.keys())
				{
					if (note != null)
					{
						if (getYFromStep(note.stepTime + holdsMap[note].holdLength) <= chartHUD.scroll.y - chartHUD.height
							|| getYFromStep(note.stepTime) >= chartHUD.scroll.y + chartHUD.height)
						{
							if (holdsMap[note].hold.visible)
							{
								if (holdsMap[note].hold != null)
									holdsMap[note].hold.visible = false;
								if (holdsMap[note].end != null)
									holdsMap[note].end.visible = false;
							}
						}

						holdsMap[note].hold.visible = true;
						holdsMap[note].end.visible = holdsMap[note].hold.visible;

						holdsMap[note].hold.x = boardPattern.x
							+ getPositionHorizontal(note.strumLine, note.noteData) * cellSize
							+ (note.width / 2 - holdsMap[note].hold.width / 2);
						holdsMap[note].hold.y = getYFromStep(note.stepTime) + cellSize / 2;

						holdsMap[note].hold.height = ((cellSize * holdsMap[note].holdLength) * chartZoom) - (cellSize * (1 - chartZoom));

						holdsMap[note].end.x = boardPattern.x
							+ getPositionHorizontal(note.strumLine, note.noteData) * cellSize
							+ (note.width / 2 - holdsMap[note].end.width / 2);
						holdsMap[note].end.y = holdsMap[note].hold.y + holdsMap[note].hold.height;

						if (holdsMap[note].hold.alive && Conductor.boundInst.playing)
						{
							var conductorPos:Float = getYFromStep(Conductor.songPosition / lastChange.stepCrochet);
							if (conductorPos >= holdsMap[note].hold.y
								&& conductorPos <= holdsMap[note].hold.y + holdsMap[note].hold.height + holdsMap[note].end.height)
							{
								receptorGroup.members[note.strumLine].receptors.members[note.noteData].playAnim('confirm');
							}
						}
					}
				}
		}*/

		for (i in receptorGroup)
		{
			for (receptor in i.receptors)
			{
				if (receptor.animation.finished)
					receptor.playAnim('static');
			}
		}

		camObject.screenCenter(X);
		camObject.y = conductorCrochet.y + (cellSize * 4);
		chartHUD.follow(camObject, FlxCameraFollowStyle.LOCKON);

		gridBackground.scrollX += (elapsed / (1 / 60)) * 0.5;
		var increaseUpTo:Float = gridBackground.height / 8;
		gridBackground.scrollY = Math.sin(totalElapsed / increaseUpTo) * increaseUpTo;
		totalElapsed += (elapsed / (1 / 60)) * 0.5;
	}

	override function onActionPressed(action:String)
	{
		switch (action)
		{
			case CONFIRM:
				{
					if (Conductor.boundInst.playing)
					{
						updateTime = false;
						Conductor.boundInst.pause();
						Conductor.boundVocals.pause();
					}
					else
					{
						lastTiming = Conductor.songPosition;
						updateTime = true;
						Conductor.boundInst.play();
						Conductor.boundVocals.play();
					}
				}
		}
	}

	function getYFromStep(step:Float):Float
	{
		return step * cellSize * chartZoom;
	}

	// get y from current step

	function getYFromCS():Float
	{
		return curStep * cellSize * chartZoom;
	}

	function sectionStartTime(add:Int = 0):Float
	{
		var bpm:Float = SONG.bpm;
		var pos:Float = 0;
		for (i in 0...curSection + add)
		{
			if (SONG.notes[i].changeBPM)
				bpm = SONG.notes[i].bpm;

			pos += 4 * (1000 * 60 / bpm);
		}
		return pos;
	}

	function getSteps():Int
	{
		var steps:Int = 16;
		if (SONG.notes[curSection].sectionBeats != null)
			steps = SONG.notes[curSection].sectionBeats * 4;
		else
			steps = SONG.notes[curSection].lengthInSteps;

		return steps;
	}

	function addSection(lengthInSteps:Int = 16):Void
	{
		var sec:SectionData = {
			lengthInSteps: lengthInSteps,
			bpm: SONG.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			altAnim: false,
			sectionBeats: null,
			gfSection: false
		};

		SONG.notes.push(sec);
	}

	function changeSection(sec:Int = 0):Void
	{
		trace('changing section $sec');

		if (SONG.notes[sec] != null)
		{
			curSection = sec;
			// update notes
			// resync?
		}
		else
			changeSection();
	}
}
