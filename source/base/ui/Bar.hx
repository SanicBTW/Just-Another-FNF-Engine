package base.ui;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;

class Bar extends FlxSpriteGroup
{
	private var _bgBar:CircularSprite;
	private var _fgBar:CircularSprite;

	private var barWidth(default, null):Int;
	private var barHeight(default, null):Int;

	private var fgColor:FlxColor;

	public var value:Float = 0;

	public function new(x:Float = 0, y:Float = 0, width:Int = 100, height:Int = 10, bgColor:FlxColor, fgColor:FlxColor)
	{
		super(x, y);

		this.barWidth = width;
		this.barHeight = height;

		this.fgColor = fgColor;

		_bgBar = new CircularSprite(x, y, barWidth, barHeight, bgColor);
		_fgBar = new CircularSprite(x, y, barWidth, barHeight, fgColor);

		add(_bgBar);
		add(_fgBar);
	}

	override public function destroy()
	{
		_bgBar = null;
		_fgBar = null;

		super.destroy();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		_fgBar.scale.x = ((value / barWidth));
	}
}
