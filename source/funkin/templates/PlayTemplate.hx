package funkin.templates;

import base.FadeTransition;
import base.MusicBeatState;
import base.system.Controls;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import funkin.notes.StrumLine;
import funkin.ui.UI;

// I Cant think of any other name tbh help
// Class/State focused on Gameplay (without characters) made to be extended by others and make changes without having to update each one by itself
class PlayTemplate<T> extends MusicBeatState
{
	// Instance to access non-static variables
	public static var instance:PlayTemplate<T>; // OMG IS THAT A GENERIC OMGOMGOMGOG

	// Camera essentials
	private var camGame:FlxCamera;
	private var camHUD:FlxCamera;
	private var camOther:FlxCamera;

	// Strums - kind of a dumb idea maybe but instead of doing a var for each strum line for the character, add both strumlines on create and access it through a var?
	private var strumLines:FlxTypedGroup<StrumLine>;

	// Gets the current strum line
	public var curStrumLine(get, null):StrumLine;

	// Should be good to override this function to add opponent mode shit right?

	@:noCompletion
	private function get_curStrumLine():StrumLine
		return strumLines.members[0];

	// Checks for the pause menu
	private var paused:Bool = false;
	private var canPause:Bool = true;

	// User Interface
	private var ui:UI;

	override function create()
	{
		if (FlxG.sound.music.playing)
			FlxG.sound.music.stop();

		Controls.setActions(NOTES);
		Timings.call();

		instance = this;

		camGame = new FlxCamera();
		camGame.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		strumLines = new FlxTypedGroup<StrumLine>();
		strumLines.cameras = [camHUD];
		add(strumLines);

		setupStrums();

		ui = new UI();
		ui.cameras = [camHUD];
		add(ui);

		FlxG.camera.zoom = 1;

		Paths.music('tea-time');
		FadeTransition.nextCamera = camOther;

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
	}

	private function setupStrums()
	{
		var strumLine:StrumLine = new StrumLine(FlxG.width / 2, 4);
		strumLines.add(strumLine);
	}
}
