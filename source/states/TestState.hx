package states;

import base.AudioStream;
import base.Conductor;
import base.MusicBeatState;
import base.ScriptableState;
import base.SoundManager;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import openfl.utils.Assets;

class TestState extends MusicBeatState
{
	var cam:FlxCamera;

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

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuDefault"));
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		var sex:FlxText = new FlxText(0, 0, 0, "me cago en mis muertos", 25);
		sex.screenCenter();
		sex.antialiasing = true;
		add(sex);
		sex.cameras = [cam];
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

		super.update(elapsed);
	}
}
