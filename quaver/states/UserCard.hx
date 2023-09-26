package states;

import backend.Cursor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import network.pocketbase.User;

class UserCard extends FlxSpriteGroup
{
	private var bg:FlxSprite;

	public var avatar:FlxSprite;
	public var userName:FlxText;

	private var _user:User = null;

	private var loaded:Bool = false;

	public function new(X:Float, Y:Float, user:User)
	{
		super(X, Y);
		this._user = user;

		bg = new FlxSprite().makeGraphic(410, 95, FlxColor.WHITE);
		bg.alpha = 0.6;

		avatar = new FlxSprite(bg.x + 15, bg.y + 15).loadGraphic(user.avatar);
		avatar.setGraphicSize(64, 64);
		avatar.updateHitbox();

		@:privateAccess
		userName = new FlxText(avatar.x + 80, bg.y + 30, 0, user._profile.record.username, 24, true);
		userName.setFormat('assets/fonts/vcr.ttf', 24, FlxColor.BLACK, CENTER);

		add(bg);
		add(avatar);
		add(userName);
	}

	override public function update(elapsed:Float)
	{
		if (!loaded && _user.avatar != null)
		{
			avatar.loadGraphic(_user.avatar);
			avatar.setGraphicSize(64, 64);
			avatar.updateHitbox();
			loaded = true;
		}

		if (FlxG.mouse.overlaps(this))
		{
			if (Cursor.curState == IDLE)
				Cursor.setCursor(HOVER);
		}
		else if (Cursor.curState == HOVER)
			Cursor.setCursor(IDLE);

		super.update(elapsed);
	}
}
