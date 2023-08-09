package funkin.notes;

import backend.ScriptHandler;
import base.Conductor;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import funkin.notes.Receptor.ReceptorData;
import haxe.Json;
import openfl.Assets;

// Find a better way to load the modules and data
class Note extends FlxSprite
{
	// If not found it will try to get this one
	private static final DEFAULT:String = "default";

	// Vanilla
	public var strumTime:Float;
	public var noteData:Int = 0;
	public var tooLate:Bool = false;
	public var canBeHit:Bool = false;
	public var wasGoodHit:Bool = false;
	public var mustPress:Bool = false;
	public var isSustain:Bool = false;
	public var isSustainEnd:Bool = false;
	public var sustainLength:Float = 0;
	public var prevNote:Note;
	public var ignoreNote:Bool = false; // Psych
	public var strumLine:Int = 0; // FE:R
	public var doubleNote:Bool = false; // JAFE

	// Sustains KE 1.6.2
	public var parent:Note = null;
	public var spotHold:Int = 0;
	public var holdActive:Bool = true;
	public var tail:Array<Note> = [];
	public var endHoldOffset:Float = Math.NEGATIVE_INFINITY; // FE:L

	// Psych
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var noteType(default, set):String = null;

	// FE:R
	public static var scriptCache:Map<String, ForeverModule> = [];
	public static var dataCache:Map<String, ReceptorData> = [];

	public var noteModule:ForeverModule;
	public var receptorData:ReceptorData;

	@:noCompletion
	private function set_noteType(value:String):String
	{
		if (noteData > -1 && noteType != value)
		{
			switch (value) {}
			noteType = value;
		}

		return value;
	}

	public function new(strumTime:Float, noteData:Int, noteType:String = 'default', strumLine:Int, ?prevNote:Note, ?isSustain:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.strumTime = strumTime;
		this.noteData = noteData;
		this.strumLine = strumLine;

		this.prevNote = prevNote;
		this.isSustain = isSustain;

		this.noteType = noteType;

		y -= 2000;

		if (noteData > -1)
			loadNote(noteType);
	}

	public function loadNote(noteType:String)
	{
		receptorData = returnNoteData(noteType);
		noteModule = returnNoteScript(noteType);

		noteModule.active = false;

		noteModule.set('getNoteDirection', getNoteDirection);
		noteModule.set('getNoteColor', getNoteColor);

		var generationScript:String = isSustain ? 'generateSustain' : 'generateNote';
		if (noteModule.exists(generationScript))
			noteModule.get(generationScript)(this);

		antialiasing = receptorData.antialiasing;
		setGraphicSize(Std.int(frameWidth * receptorData.size));
		updateHitbox();

		updateSustainScale();
	}

	public function updateSustainScale()
	{
		if (isSustain)
		{
			alpha = 0.6;
			if (prevNote != null && prevNote.exists)
			{
				if (prevNote.isSustain)
				{
					prevNote.scale.y = (prevNote.width / prevNote.frameWidth) * ((Conductor.stepCrochet / 100) * (2.375 / prevNote.receptorData.size)) * Conductor.songSpeed;
					prevNote.updateHitbox();
					offsetX = prevNote.offsetX;
				}
				else
					offsetX = ((prevNote.width / 2) - (width / 2));
			}
		}
	}

	public static function returnNoteData(noteType:String):ReceptorData
	{
		if (!dataCache.exists(noteType))
		{
			trace('Setting note data $noteType');

			// i forgot
			var path:String = Paths.file('notetypes/$noteType/$noteType.json');
			if (!Assets.exists(path))
				path = Paths.file('notetypes/$DEFAULT/$DEFAULT.json');

			dataCache.set(noteType, cast Json.parse(Paths.text(path)));
		}
		return dataCache.get(noteType);
	}

	public static function returnNoteScript(noteType:String):ForeverModule
	{
		// load up the note script
		if (!scriptCache.exists(noteType))
		{
			trace('Setting note script $noteType');
			var module:ForeverModule = ScriptHandler.loadModule(noteType, 'notetypes/$noteType', DEFAULT);
			// We don't want the note script to get updated all the time
			module.active = false;
			scriptCache.set(noteType, module);
		}
		return scriptCache.get(noteType);
	}

	public function getNoteDirection()
		return receptorData.actions[noteData];

	public function getNoteColor()
		return receptorData.colors[noteData];

	override function update(elapsed:Float)
	{
		if (mustPress)
		{
			switch (Settings.ratingStyle)
			{
				case KADE:
					var diff:Float = strumTime - Conductor.songPosition;

					if (isSustain)
						canBeHit = (diff <= ((166 * Conductor.timeScale) * .5) && diff >= (-166 * Conductor.timeScale));
					else
						canBeHit = (diff <= ((166 * Conductor.timeScale)) && diff >= (-166 * Conductor.timeScale));

					tooLate = (diff < -166 && !wasGoodHit);

				case PSYCH:
					if (isSustain)
						canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * .5)
							&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * .5));
					else
						canBeHit = (strumTime > (Conductor.songPosition - Conductor.safeZoneOffset)
							&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * .5));

					tooLate = (strumTime < (Conductor.songPosition - Conductor.safeZoneOffset) && !wasGoodHit);
			}
		}

		if (tooLate || (parent != null && parent.tooLate))
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}

		super.update(elapsed);
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}
