package funkin.notes;

import backend.scripting.ForeverModule;
import flixel.FlxSprite;

typedef ReceptorData =
{
	var keyAmount:Int;
	var actions:Array<String>;
	var colors:Array<String>;
	var separation:Float;
	var size:Float;
	var antialiasing:Bool;
}

class Receptor extends FlxSprite
{
	public var swagWidth:Float;

	public var noteData:Int;
	public var noteType:String;
	public var action:String;

	public var receptorData:ReceptorData;
	public var noteModule:ForeverModule;

	public var initialX:Int;
	public var initialY:Int;

	public var setAlpha:Float = 0.8;

	public var holdTimer:Float = 0;
	public var direction:Float = 90;

	public function new(receptorData:ReceptorData, ?noteData:Int = 0, ?noteType:String = 'default')
	{
		super();

		this.receptorData = receptorData;
		this.noteData = noteData;
		this.noteType = noteType;

		noteModule = Note.returnNoteScript(noteType);
		noteModule.set('getNoteDirection', getNoteDirection);
		noteModule.set('getNoteColor', getNoteColor);
		noteModule.get('generateReceptor')(this);
	}

	override function update(elapsed:Float)
	{
		if (holdTimer > 0)
		{
			holdTimer -= elapsed;
			if (holdTimer <= 0)
			{
				playAnim('static');
				holdTimer = 0;
			}
		}

		if (animation.curAnim != null && animation.curAnim.name == 'confirm')
			centerOrigin();

		super.update(elapsed);
	}

	public function playAnim(AnimName:String, Force:Bool = false)
	{
		// Fallback to basic animations if not found on animation controller (NOT TESTED)
		if (animation.exists(AnimName))
		{
			if (AnimName == "confirm")
			{
				alpha = 1;
				centerOrigin();
			}
			else
				alpha = setAlpha;

			animation.play(AnimName, Force);
		}
		else
		{
			switch (AnimName)
			{
				case "static":
					alpha = setAlpha;
					scale.set(1, 1);
				case "pressed":
					alpha = setAlpha;
					scale.set(0.95, 0.95);
				case "confirm":
					alpha = 1;
					scale.set(0.9, 0.9);
			}
		}

		centerOffsets();
		centerOrigin();
	}

	public function getNoteDirection()
		return receptorData.actions[noteData];

	public function getNoteColor()
		return receptorData.colors[noteData];
}
