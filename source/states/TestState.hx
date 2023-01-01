package states;

import base.Alphabet;
import base.Conductor;
import base.MusicBeatState;
import base.ScriptableState;
import base.SoundManager.AudioStream;
import base.SoundManager;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.utils.Assets;

class TestState extends MusicBeatState
{
	var cam:FlxCamera;
	var beatText:Alphabet;
	var stepText:Alphabet;

	override public function create()
	{
		var instStream:AudioStream = new AudioStream();
		instStream.source = Paths.music("Inst");

		var voicesStream:AudioStream = new AudioStream();
		voicesStream.source = Paths.music("Voices");

		Conductor.bindSong(this, instStream, 150, voicesStream);

		cam = new FlxCamera();
		cam.bgColor.alpha = 0;
		FlxG.cameras.add(cam);

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuSDefault"));
		bg.color = FlxColor.BLUE;
		bg.alpha = 0.6;
		bg.screenCenter();
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.antialiasing = true;
		add(bg);

		var sex:Alphabet = new Alphabet(0, 0, "me cago en mis muertos", true);
		sex.screenCenter();
		add(sex);

		stepText = new Alphabet(0, 0, "CurStep: 0", true);
		add(stepText);
		beatText = new Alphabet(0, (stepText.y + stepText.height) + 10, "CurBeat: 0", true);
		add(beatText);

		sex.cameras = [cam];
		stepText.cameras = [cam];
		beatText.cameras = [cam];
		super.create();

		Conductor.boundSong.play();
		Conductor.boundVocals.play();
		Conductor.resyncTime();
	}

	override public function beatHit()
	{
		super.beatHit();

		if (Conductor.beatPosition % 4 == 0)
			cam.zoom += 0.05;
	}

	override public function update(elapsed:Float)
	{
		cam.zoom = FlxMath.lerp(1, cam.zoom, 0.95);

		stepText.changeText('CurStep: ${Conductor.stepPosition}');
		beatText.changeText('CurBeat: ${Conductor.beatPosition}');

		super.update(elapsed);
	}
}
