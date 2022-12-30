package;

import base.AudioStream;
import base.Conductor;
import base.MusicBeatState;
import base.Paths;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import openfl.utils.Assets;

class PlayState extends MusicBeatState
{
	var cam:FlxCamera;
	var audioStream:AudioStream = new AudioStream();

	override public function create()
	{
		audioStream.source = Paths.music("test");
		audioStream.onComplete = function(?_)
		{
			Conductor.bindSong(this, audioStream, 128);
		}
		Conductor.bindSong(this, audioStream, 128);
		sounds.push(audioStream);

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
	}

	override public function beatHit()
	{
		super.beatHit();

		if (Conductor.beatPosition % 4 == 2)
			cam.zoom += 0.05;
	}

	override public function update(elapsed:Float)
	{
		cam.zoom = FlxMath.lerp(1, cam.zoom, 0.95);

		super.update(elapsed);
	}

	override private function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		switch (action)
		{
			case "confirm":
				if (Conductor.boundSong.playing)
					Conductor.boundSong.stop();
				else
					Conductor.boundSong.play();
		}
	}
}
