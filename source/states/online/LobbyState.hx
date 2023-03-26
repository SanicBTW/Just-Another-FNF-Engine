package states.online;

import base.MusicBeatState;
import base.ScriptableState;
import base.system.Conductor;
import base.system.DiscordPresence;
import base.ui.Fonts;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;
import funkin.Character;
import funkin.Stage;
import io.colyseus.Room;
import openfl.desktop.Clipboard;
import states.online.schema.VersusRoom;

class LobbyState extends MusicBeatState
{
	public static var room:Room<VersusRoom>;

	public static var roomCode:String;

	public static var readyTxt:FlxTypedGroup<FlxBitmapText>;

	private static var p1:Character;
	public static var p2:Character;

	private static var codeText:FlxBitmapText;
	private static var modeText:FlxBitmapText;
	private static var p1Name:FlxBitmapText;
	private static var p2Name:FlxBitmapText;

	private var ready:Bool = false;

	private var stage:Stage;

	private var curMode(default, set):Int = 0;
	private final modes:Array<String> = ["Score", "Accuracy", "Misses"];

	@:noCompletion
	private function set_curMode(value:Int):Int
	{
		curMode += value;

		if (curMode < 0)
			curMode = modes.length - 1;
		if (curMode >= modes.length)
			curMode = 0;

		room.send('set_rateMode', {mode: modes[curMode]});

		return curMode;
	}

	public static var rateMode:String = "?";

	override function create()
	{
		stage = new Stage("stage");
		add(stage);

		codeText = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(codeText, false, 0.6);
		codeText.text = 'Room code: ${roomCode}';
		codeText.setPosition(5, FlxG.height * 0.001);

		modeText = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(modeText, false, 0.6);
		modeText.text = 'Rate mode: ?';
		modeText.setPosition(5, (codeText.y + codeText.height) + 5);

		p1 = new Character(180, -100, false, 'bf');
		p2 = new Character(660, -100, true, 'bf');
		p2.alpha = 0.4;
		if (ConnectingState.mode == 'join')
			p2.alpha = 1;

		p1Name = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(p1Name, false, 0.5);
		p1Name.setPosition(p1.x + 100, p1.y - 30);

		p2Name = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(p2Name, false, 0.5);
		p2Name.setPosition(p2.x + 100, p2.y - 30);

		readyTxt = new FlxTypedGroup<FlxBitmapText>();
		var readyState:FlxBitmapText = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(readyState, false, 0.6);
		readyState.setPosition(p1.x, p1.y);
		readyState.text = "Not ready";
		readyState.color = FlxColor.RED;
		readyTxt.add(readyState);

		var readyState:FlxBitmapText = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(readyState, false, 0.6);
		readyState.setPosition(p2.x, p2.y);
		readyState.text = "Not ready";
		readyState.color = FlxColor.RED;
		readyTxt.add(readyState);

		add(p1);
		add(p2);
		add(p1Name);
		add(p2Name);
		add(codeText);
		add(modeText);
		add(readyTxt);

		super.create();

		DiscordPresence.changePresence('In the lobby', roomCode);

		if (ConnectingState.mode == 'host')
			curMode = 0;
	}

	override public function update(elapsed:Float)
	{
		p1Name.text = ConnectingState.p1name;
		p2Name.text = ConnectingState.p2name;
		modeText.text = 'Rate mode: ${rateMode}';

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(codeText))
			Clipboard.generalClipboard.setData(TEXT_FORMAT, '`${roomCode}`');

		if (FlxG.keys.justPressed.M)
			curMode += 1;

		super.update(elapsed);
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (action == "back")
		{
			room.leave();
			ScriptableState.switchState(new AlphabetMenu());
		}

		if (action == "confirm")
		{
			ready = !ready;
			room.send("set_ready", {ready: ready});
		}
	}
}
