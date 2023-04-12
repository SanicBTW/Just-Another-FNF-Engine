package window_ui;

import openfl.Lib;
import openfl.display.Sprite;

// Made so I can update code automatically across files that extend this class
class Tray extends Sprite
{
	// Update only when its active
	public var active:Bool = false;

	// Default scale for the tray, each tray class will have its own width and height
	private var _defaultScale:Float = 2.0;

	public function new()
	{
		super();

		visible = false;

		screenCenter();

		create();
	}

	// Fired after setting up some essentials on constructor

	private function create() {}

	// Triggers the update function passing elapsed-a-like from FlxG
	// Instead of getting it from a getter and improving update calls)?

	@:noCompletion
	private override function __enterFrame(deltaTime:Float):Void
	{
		if (!active || !visible)
			return;

		update(deltaTime / 1000);
	}

	public function update(elapsed:Float) {}

	public function screenCenter()
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		x = (0.5 * (Lib.current.stage.stageWidth - Std.parseFloat(Reflect.getProperty(this, "_width")) * _defaultScale));
	}
}
