package states.online.ui;

import base.system.Conductor;
import base.ui.Bar;
import base.ui.Fonts;
import base.ui.TextComponent;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;
import funkin.CoolUtil;
import states.online.ConnectingState.PlayerData;

class OnlineUI extends FlxSpriteGroup
{
	public var player1Info:PlayerInfo;
	public var player2Info:PlayerInfo;

	public function new()
	{
		super();

		player1Info = new PlayerInfo(30, ((FlxG.height / 2) + (FlxG.height / 4)), 550, 58, 1);
		player2Info = new PlayerInfo(30, (FlxG.height / 2) + (FlxG.height / 4), 550, 58, 2);
		player2Info.yAdd = 63;

		add(player1Info);
		add(player2Info);
	}

	public function updateStats(p1:PlayerData, p2:PlayerData)
	{
		player1Info.changeText(null, 'Accuracy ${p1.accuracy}% | Score ${p1.score} | Misses ${p1.misses}');

		player2Info.changeText(null, 'Accuracy ${p2.accuracy}% | Score ${p2.score} | Misses ${p2.misses}');

		if (p1.score > p2.score)
		{
			player1Info.yAdd = 0;
			player2Info.yAdd = 63;
		}
		else
		{
			player1Info.yAdd = 63;
			player2Info.yAdd = 0;
		}
	}
}

class PlayerInfo extends FlxSpriteGroup
{
	private var bg:FlxSprite;

	// I had no chance sorry
	// Might move onto this if I find a way to actually properly scale the bitmap used to render the text
	private var header:TextComponent;
	private var info:TextComponent;

	private var player:Int;

	private var yMult:Float = 58;
	private var targetY:Float = 0;

	public var yAdd:Float = 0;

	public function new(X:Float, Y:Float, Width:Int, Height:Int, Player:Int = 1)
	{
		super(X, Y);

		player = Player;

		header = new TextComponent(0, 0, Width, 'Player $player', 20);
		header.antialiasing = SaveData.antialiasing;

		info = new TextComponent(0, header.height + 5, Width, 'Accuracy ? | Score 0 | Misses 0', 22);
		info.antialiasing = SaveData.antialiasing;

		bg = new FlxSprite().makeGraphic(Width, Height, FlxColor.BLACK);
		bg.alpha = 0.4;
		bg.antialiasing = SaveData.antialiasing;

		add(bg);
		add(header);
		add(info);
	}

	override public function update(elapsed:Float)
	{
		var slowLerp:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		var scaledY:Float = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
		y = FlxMath.lerp(y, (scaledY * yMult) + ((FlxG.height / 2) + (FlxG.height / 4)) + yAdd, slowLerp);

		super.update(elapsed);
	}

	public function changeText(?appendHeader:String, newInfo:String)
	{
		header.text = 'Player $player ${appendHeader != null ? ' - $appendHeader' : ""}';
		info.text = newInfo;
	}
}
