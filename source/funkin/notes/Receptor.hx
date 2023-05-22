package funkin.notes;

import backend.ScriptHandler;
import base.Conductor;
import flixel.FlxSprite;
import haxe.ds.IntMap;

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
	public var direction:Float = 0;

	public function new(receptorData:ReceptorData, ?noteData:Int = 0, ?noteType:String = 'default')
	{
		super();

		this.receptorData = receptorData;
		this.noteData = noteData;
		this.noteType = noteType;

		noteModule = Note.returnNoteScript(noteType);
		noteModule.interp.variables.set('receptor', this);
		noteModule.interp.variables.set('getNoteDirection', getNoteDirection);
		noteModule.interp.variables.set('getNoteColor', getNoteColor);
		noteModule.get('generateReceptor')();
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
		if (AnimName == "confirm")
		{
			alpha = 1;
			centerOrigin();
		}
		else
			alpha = setAlpha;

		animation.play(AnimName, Force);
		centerOffsets();
		centerOrigin();
	}

	public function getNoteDirection()
		return receptorData.actions[noteData];

	public function getNoteColor()
		return receptorData.colors[noteData];
}
