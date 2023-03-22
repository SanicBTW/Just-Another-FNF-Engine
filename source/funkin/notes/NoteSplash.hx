package funkin.notes;

import flixel.FlxG;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite
{
	override public function new(X:Float, Y:Float, noteData:Int)
	{
		super(X, Y);

		loadGraphic(Paths.image('noteSplashes'), true, 210, 210);
		animation.add('anim1', [
			(noteData * 2 + 1),
			8 + (noteData * 2 + 1),
			16 + (noteData * 2 + 1),
			24 + (noteData * 2 + 1),
			32 + (noteData * 2 + 1)
		], 24, false);
		animation.add('anim2', [
			(noteData * 2),
			8 + (noteData * 2),
			16 + (noteData * 2),
			24 + (noteData * 2),
			32 + (noteData * 2)
		], 24, false);

		alpha = 0.6;
		visible = false;
		x -= width / 4;
		y -= height / 4;
		antialiasing = SaveData.antialiasing;
	}

	public function playAnim()
	{
		visible = true;
		animation.play('anim${FlxG.random.int(1, 2)}', true);
		if (animation.curAnim != null)
			animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
	}

	override public function update(elapsed:Float)
	{
		if (animation.curAnim != null)
			if (animation.curAnim.finished)
				visible = false;

		super.update(elapsed);
	}
}
