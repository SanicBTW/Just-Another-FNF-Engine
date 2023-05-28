package funkin.notes;

import backend.ScriptHandler;
import base.Conductor;
import flixel.FlxSprite;
import funkin.notes.Receptor.ReceptorData;
import haxe.Json;
import openfl.Assets;

// Rewrite soon
class Note extends FlxSprite
{
	public static var swagWidth:Float = 160 * 0.7;

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

	// Psych
	public var ignoreNote:Bool = false;

	// FE:R
	public var strumLine:Int = 0;

	// JAFE
	public var doubleNote:Bool = false;

	// Sustains (Andromeda:L - HOLDS V2)
	public var parent:Note;
	public var tail:Array<Note> = [];
	public var unhitTail:Array<Note> = [];
	public var tripTimer:Float = 1;
	public var holdingTime:Float = 0;

	// Andromeda:L
	public var hitbox:Float = 166;

	// Psych
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	// Psych
	public var noteType(default, set):String = null;

	// FE:L
	public var endHoldOffset:Float = Math.NEGATIVE_INFINITY;

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
			loadNote(value);
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
	}

	public function loadNote(noteType:String)
	{
		receptorData = returnNoteData(noteType);
		noteModule = returnNoteScript(noteType);

		noteModule.active = false;

		noteModule.interp.variables.set('note', this);
		noteModule.interp.variables.set('getNoteDirection', getNoteDirection);
		noteModule.interp.variables.set('getNoteColor', getNoteColor);

		var generationScript:String = isSustain ? 'generateSustain' : 'generateNote';
		if (noteModule.exists(generationScript))
			noteModule.get(generationScript)();

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
					prevNote.scale.y = (prevNote.width / prevNote.frameWidth) * ((Conductor.stepCrochet / 100) * (2.4 / prevNote.receptorData.size)) * Conductor.songSpeed;
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
			var diff:Float = Math.abs(strumTime - Conductor.songPosition);

			if (isSustain)
				canBeHit = (diff <= ((hitbox * Conductor.timeScale) * .5) && diff >= (-hitbox * Conductor.timeScale) * .5);
			else
				canBeHit = (diff <= ((hitbox * Conductor.timeScale)) && diff >= (-hitbox * Conductor.timeScale));
		}

		if (tooLate || (parent != null && parent.tooLate))
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}

		super.update(elapsed);
	}
}
