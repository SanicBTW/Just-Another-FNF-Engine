package window_ui;

import flixel.FlxG;
import flixel.math.FlxMath;
import funkin.CoolUtil;
import lime.app.Event;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

// Just a Tray which acts like a notification with a dismiss time and some content displaying important info
// Its an OpenFL Sprite to avoid having to manage it in Flixel
// Some code comes from VolumeTray
// Gotta rewrite this but works for now, its ugly tho
class NotificationTray extends Sprite
{
	// Update only when its active
	public var active:Bool = false;

	// Time until the notification is dismissed
	private var _dismissTime:Float = 0.0;

	// If its currently notifying
	private var _notifying:Bool = false;

	// Sizes
	private var _width:Int = 200;
	private var _height:Int = 50;
	private var _defaultScale:Float = 2.0;

	// Lerps everywheree
	private var targetY:Float = 0.0;

	// The notification tray gets updated on the update event of the application, uses FlxG elapsed to get the time since last frame
	private var elapsed(get, null):Float;

	@:noCompletion
	private function get_elapsed():Float
		return FlxG.elapsed;

	// Sprites
	private var _header:TextField;
	private var _info:TextField;
	private var _dismissProgress:Bitmap;

	// Events
	public static var onNotificationFinish:Event<Void->Void> = new Event<Void->Void>();

	@:keep
	public function new()
	{
		super();

		visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		y = -Lib.current.stage.stageHeight;

		var bg:Bitmap = new Bitmap(new BitmapData(_width, _height, true, 0x7F000000));
		screenCenter();
		addChild(bg);

		_header = new TextField();
		setTxtFieldProperties(_header);
		_header.text = 'Placeholder';
		addChild(_header);

		_info = new TextField();
		setTxtFieldProperties(_info, 12);
		_info.text = "Placeholder";
		_info.y = 16.5;
		addChild(_info);

		var bgBar:Bitmap = new Bitmap(new BitmapData(_width, 5, false, 0xFFFFFF));
		bgBar.y = (_height - bgBar.height);
		addChild(bgBar);

		// 0x0FFF50
		// 0x90EE90
		_dismissProgress = new Bitmap(new BitmapData(_width, 5, false, 0x0FFF50));
		_dismissProgress.scaleX = 0.4;
		_dismissProgress.y = (_height - _dismissProgress.height);
		addChild(_dismissProgress);
	}

	public function update()
	{
		y = FlxMath.lerp(targetY, y, CoolUtil.boundTo(1 - (elapsed * 9.4), 0, 1));
		_dismissProgress.scaleX = FlxMath.lerp(_dismissTime / _dismissProgress.width, _dismissProgress.scaleX, CoolUtil.boundTo(1 - (elapsed * 8.6), 0, 1));

		if (_notifying)
		{
			_dismissTime += elapsed * _dismissProgress.width / 2;

			if (_dismissTime >= _dismissProgress.width)
			{
				targetY -= elapsed * FlxG.height * _defaultScale;

				if (y <= -height)
					close();
			}
		}
	}

	public function notify(header:String, info:String = '')
	{
		if (!_notifying)
		{
			_notifying = active = visible = true;

			_header.text = header;
			_info.text = info;
			targetY = 0;
		}
		else
			close(true, header, info);
	}

	public function close(overriden:Bool = false, ?header:String, ?info:String)
	{
		_notifying = false;
		_dismissTime = 0;

		if (overriden)
		{
			notify(header, info);
			return;
		}

		visible = false;
		_header.text = '';
		_info.text = '';
		onNotificationFinish.dispatch();
	}

	public function screenCenter()
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale));
	}

	private function setTxtFieldProperties(field:TextField, size:Int = 14)
	{
		field.defaultTextFormat = new TextFormat(Assets.getFont(Paths.font("funkin.otf")).fontName, size, 0xFFFFFF);
		field.defaultTextFormat.align = LEFT;
		field.width = _width;
		field.multiline = false;
		field.wordWrap = true;
		field.selectable = false;
		field.embedFonts = true;
		field.y = 2.5;
		field.x = 2.5;
	}
}
