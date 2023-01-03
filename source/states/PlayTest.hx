package states;

import base.Conductor;
import base.Controls;
import base.MusicBeatState;
import base.SoundManager.AudioStream;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import funkin.ChartLoader;
import funkin.notes.Note;
import funkin.notes.StrumLine;

class PlayTest extends MusicBeatState
{
	public static var SONG:Song;
	public static var camHUD:FlxCamera;

	var strumLines:FlxTypedGroup<StrumLine>;

	private var opponentStrums:StrumLine;
	private var playerStrums:StrumLine;

	@:isVar private var curStep(get, null):Int;

	private function get_curStep():Int
		return Conductor.stepPosition;

	public static var songSpeed:Float = 0;

	public var downscroll:Bool = false;

	private var generatedMusic:Bool = false;

	override function create()
	{
		Paths.clearStoredMemory();
		Controls.setActions(NOTES);

		generateSong();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD);

		Conductor.boundSong.play();
		Conductor.boundVocals.play();

		strumLines = new FlxTypedGroup<StrumLine>();
		var separation:Float = FlxG.width / 4;
		opponentStrums = new StrumLine((FlxG.width / 2) - separation, 4);
		strumLines.add(opponentStrums);
		playerStrums = new StrumLine((FlxG.width / 2) + separation, 4);
		strumLines.add(playerStrums);
		add(strumLines);
		strumLines.cameras = [camHUD];

		super.create();

		Conductor.resyncTime();
		Paths.clearUnusedMemory();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (generatedMusic && SONG.notes[Std.int(curStep / 16)] != null)
		{
			parseEventColumn(ChartLoader.unspawnedNoteList, function(unspawnNote:Note)
			{
				var strumLine:StrumLine = strumLines.members[unspawnNote.strumLine];
				if (strumLine != null)
					strumLine.add(unspawnNote);
			}, -(16 * Conductor.stepCrochet));

			var downscrollMultiplier:Int = (!downscroll ? 1 : -1) * FlxMath.signOf(songSpeed);

			for (strumLine in strumLines)
			{
				for (receptor in strumLine.receptors)
				{
					if (strumLine.botPlay && receptor.animation.finished)
						receptor.playAnim('static');
				}

				strumLine.allNotes.forEachAlive(function(strumNote:Note)
				{
					if (strumNote.tooLate)
					{
						strumNote.active = false;
						strumNote.visible = false;
					}
					else
					{
						strumNote.visible = true;
						strumNote.active = false;
					}

					strumNote.noteSpeed = Math.abs(songSpeed);
					var roundedSpeed = FlxMath.roundDecimal(strumNote.noteSpeed, 2);

					var baseX = strumLine.receptors.members[Math.floor(strumNote.noteData)].x;
					var baseY = strumLine.receptors.members[Math.floor(strumNote.noteData)].y;
					strumNote.x = baseX + strumNote.offsetX;
					strumNote.y = baseY
						+ strumNote.offsetY
						+ (downscrollMultiplier * -((Conductor.songPosition - (strumNote.stepTime * Conductor.stepCrochet)) * (0.45 * roundedSpeed)));

					var center:Float = baseY + (Note.swagWidth / 2);
					if (strumNote.isSustain)
					{
						strumNote.y -= ((Note.swagWidth / 2) * downscrollMultiplier);

						if (downscrollMultiplier < 0)
						{
							strumNote.flipY = true;
							if (strumNote.y - strumNote.offset.y * strumNote.scale.y + strumNote.height >= center
								&& (strumLine.botPlay
									|| (strumNote.wasGoodHit || (strumNote.prevNote != null && strumNote.prevNote.wasGoodHit))))
							{
								var swagRect = new FlxRect(0, 0, strumNote.frameWidth, strumNote.frameHeight);
								swagRect.height = (center - strumNote.y) / strumNote.scale.y;
								swagRect.y = strumNote.frameHeight - swagRect.height;
								strumNote.clipRect = swagRect;
							}
						}
						else if (downscrollMultiplier > 0)
						{
							if (strumNote.y + strumNote.offset.y * strumNote.scale.y <= center
								&& (strumLine.botPlay
									|| (strumNote.wasGoodHit || (strumNote.prevNote != null && strumNote.prevNote.wasGoodHit))))
							{
								var swagRect = new FlxRect(0, 0, strumNote.width / strumNote.scale.x, strumNote.height / strumNote.scale.y);
								swagRect.y = (center - strumNote.y) / strumNote.scale.y;
								swagRect.height -= swagRect.y;
								strumNote.clipRect = swagRect;
							}
						}
					}
				});
			}
		}
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);
	}

	public function parseEventColumn(eventColumn:Array<Dynamic>, functionToCall:Dynamic->Void, ?timeDelay:Float = 0)
	{
		// check if there even are events to begin with
		if (eventColumn.length > 0)
		{
			while (eventColumn[0] != null && (eventColumn[0].stepTime + timeDelay / Conductor.stepCrochet) <= Conductor.stepPosition)
			{
				if (functionToCall != null)
					functionToCall(eventColumn[0]);
				eventColumn.splice(eventColumn.indexOf(eventColumn[0]), 1);
			}
		}
	}

	private function generateSong():Void
	{
		SONG = ChartLoader.loadChart(this, "bopeebo", 2);
		songSpeed = SONG.speed;

		generatedMusic = true;
	}
}
