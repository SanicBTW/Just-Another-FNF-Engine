package window;

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.ColorTween;
import flixel.util.FlxColor;
import openfl.display.Shape;
import window.components.Slider;

class VolumePanel extends ExSprite
{
	private var _defaultScale:Float = 2.0;

	private var _visibleTime:Float = 0;

	private var _width:Int = 240;
	private var _height:Int = 100;
	private var _outlineSize:Int = 5;

	private var targetX:Float = 0.0;
	private var targetY:Float = 0.0;

	private var _bg:Shape;
	private var _outline:Shape;

	private var _tracker:Slider;
	private var _colorTween:ColorTween;

	override public function create()
	{
		_outline = drawRound(0, 0, _width + _outlineSize, _height + _outlineSize, [15], FlxColor.BLACK, 0.25);
		_bg = drawRound(_outlineSize * 0.5, _outlineSize * 0.5, _width, _height, [15], FlxColor.WHITE, 0.6);

		// 15 cuz corner radius, and uhhh the rest i hate myself
		_tracker = new Slider(_width - (_outlineSize * 2) - 15, 7);
		_tracker.x = (_bg.width - _tracker.width) * 0.5;
		_tracker.y = (_bg.height - _tracker.height) * 0.5;

		_width += _outlineSize;
		_height += _outlineSize;

		screenCenter();
		addChild(_outline);
		addChild(_bg);
		addChild(_tracker);

		FlxG.signals.gameResized.add((w, h) ->
		{
			reposition(w, h);
		});

		FlxG.sound.volumeHandler = (vol:Float) ->
		{
			if (_colorTween != null)
				_colorTween.cancel();

			if (vol == 0)
			{
				_colorTween = FlxTween.color(null, 0.4, _tracker.bgColor, FlxColor.RED, {
					onUpdate: (_) ->
					{
						_tracker.bgColor = _colorTween.color;
					},
					onComplete: (_) ->
					{
						_colorTween = null;
					}
				});
			}
			else
			{
				_colorTween = FlxTween.color(null, 0.4, _tracker.bgColor, FlxColor.WHITE, {
					onUpdate: (_) ->
					{
						_tracker.bgColor = _colorTween.color;
					},
					onComplete: (_) ->
					{
						_colorTween = null;
					}
				});
			}

			_tracker.progress = vol;
		}
	}

	override function update(elapsed:Float, deltaTime:Float)
	{
		var lerpVal:Float = flixel.math.FlxMath.bound(1 - (elapsed * 7.315), 0, 1);

		lerpTrack(this, "x", targetX, lerpVal);
		lerpTrack(this, "y", targetY, lerpVal);

		// For some fucking reason it wont update automatically and i didnt do shit about the base code fr
		_tracker.update(elapsed, deltaTime);
	}

	override function screenCenter()
	{
		scaleX = scaleY = _defaultScale;

		targetX = (0.5 * (openfl.Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
		targetY = (0.5 * (openfl.Lib.current.stage.stageHeight - _height * _defaultScale) - FlxG.game.y);
	}

	function reposition(newWidth:Float, newHeight:Float)
	{
		// cuz uh
		var margin:Float = (_outlineSize * 2);
		targetX = (newWidth - (_width + _outline.width)) - margin;
		targetY = (newHeight - (_height + _outline.height)) - margin;
	}
}
