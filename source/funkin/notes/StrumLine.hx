package funkin.notes;

import base.Conductor;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import states.PlayTest;

class StrumLine extends FlxTypedGroup<FlxBasic>
{
	public var receptors:FlxTypedGroup<Receptor>;
	public var notesGroup:FlxTypedGroup<Note>;
	public var holdGroup:FlxTypedGroup<Note>;
	public var allNotes:FlxTypedGroup<Note>;
	public var botPlay:Bool = false;

	public function new(x:Float = 0, keyAmount:Int = 4)
	{
		super();

		receptors = new FlxTypedGroup<Receptor>();
		notesGroup = new FlxTypedGroup<Note>();
		holdGroup = new FlxTypedGroup<Note>();
		allNotes = new FlxTypedGroup<Note>();

		for (i in 0...keyAmount)
		{
			var receptor:Receptor = new Receptor(x, 60, i);
			receptor.ID = i;

			// receptor.action = 'note_${Receptor.getArrowFromNum(i)}'; // for the next time i use "action" var on the receptor, i fixed it now cuz i just noticed
			receptor.x -= ((keyAmount / 2) * Note.swagWidth);
			receptor.x += (Note.swagWidth * i);
			receptors.add(receptor);

			receptor.initialX = Math.floor(receptor.x);
			receptor.initialY = Math.floor(receptor.y);
			receptor.playAnim('static');

			receptor.y -= 20;
			receptor.alpha = 0;

			FlxTween.tween(receptor, {y: receptor.initialY, alpha: receptor.setAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
		}

		add(holdGroup);
		add(receptors);
		add(notesGroup);
	}

	public function push(newNote:Note)
	{
		(newNote.isSustain ? holdGroup.add(newNote) : notesGroup.add(newNote));
		allNotes.add(newNote);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		allNotes.forEachAlive(function(strumNote:Note)
		{
			strumNote.update(elapsed); // force the note to update because it wont automatically
		});
	}
}
