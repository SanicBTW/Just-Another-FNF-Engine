package flixel.addons.ui;

// Mix between https://github.com/SanicBTW/Just-Another-FNF-Engine/blob/android-0.2.7.1/source/base/touch/flixel/FlxHitbox.hx#L22
// and https://github.com/SanicBTW/Rolling-Again-Port/blob/0a34b2988aec2905508333ad1674694fb1a78fec/source/ui/Hitbox.hx
// Modified to fix the input problems
import backend.input.Controls;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.math.*;
import flixel.tweens.*;
import flixel.ui.FlxButton;
import openfl.events.TouchEvent;

using backend.Extensions;

/**
 * A hitbox.
 * It's easy to customize the layout.
 *
 * @author: Saw (M.A. Jigsaw)
 * @modification: SanicBTW
 */
class FlxHitbox extends FlxSpriteGroup
{
	public var overlay:FlxSprite = new FlxSprite(0, 0);
	public var buttonLeft:FlxButton = new FlxButton(0, 0);
	public var buttonDown:FlxButton = new FlxButton(0, 0);
	public var buttonUp:FlxButton = new FlxButton(0, 0);
	public var buttonRight:FlxButton = new FlxButton(0, 0);

	private var regions:Array<
		{
			action:ActionType,
			region:FlxRect
		}> = [];

	/**
	 * Create a hitbox.
	 */
	public function new()
	{
		super();

		scrollFactor.set();

		overlay.loadGraphic(Paths.image("ui/touch/hitbox/hitbox_hint"));
		overlay.setGraphicSize(FlxG.width);

		add(overlay);

		FlxG.stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
		FlxG.stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);

		add(buttonLeft = createHint(0, 0, 'left', 0xFFFF00FF));
		add(buttonDown = createHint(FlxG.width / 4, 0, 'down', 0xFF00FFFF));
		add(buttonUp = createHint(FlxG.width / 2, 0, 'up', 0xFF00FF00));
		add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), 0, 'right', 0xFFFF0000));
	}

	override function destroy()
	{
		super.destroy();

		FlxG.stage.removeEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
		FlxG.stage.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);

		overlay = null;
		buttonLeft = null;
		buttonDown = null;
		buttonUp = null;
		buttonRight = null;
	}

	private function onTouchBegin(ev:TouchEvent)
	{
		var localX:Float = ev.localX;
		var localY:Float = ev.localY;

		var point:FlxPoint = FlxPoint.weak(localX, localY);
		var reg = regions.findFirst((f) ->
		{
			return point.inRect(f.region);
		});

		if (reg == null)
			return;

		Controls.dispatchPressed(reg.action);
	}

	private function onTouchEnd(ev:TouchEvent)
	{
		var localX:Float = ev.localX;
		var localY:Float = ev.localY;

		var point:FlxPoint = FlxPoint.weak(localX, localY);
		var reg = regions.findFirst((f) ->
		{
			return point.inRect(f.region);
		});

		if (reg == null)
			return;

		Controls.dispatchReleased(reg.action);
	}

	private function createHint(X:Float, Y:Float, Graphic:String, ?Color:Int = 0xFFFFFF):FlxButton
	{
		var hintTween:FlxTween = null;
		var hint:FlxButton = new FlxButton(X, Y);
		hint.loadGraphic(FlxGraphic.fromFrame(Paths.getSparrowAtlas("ui/touch/hitbox/hitbox").getByName(Graphic)));
		hint.setGraphicSize(Std.int(FlxG.width / 4), FlxG.height);
		hint.updateHitbox();
		hint.scrollFactor.set();
		hint.color = Color;
		hint.alpha = 0.00001;

		regions.push({action: cast 'NOTE_${Graphic.toUpperCase()}', region: hint.getHitbox()});

		hint.onDown.callback = function()
		{
			if (hintTween != null)
				hintTween.cancel();

			hintTween = FlxTween.num(hint.alpha, 0.6, 0.06, {ease: FlxEase.circInOut}, function(value:Float)
			{
				hint.alpha = value;
			});
		}
		hint.onUp.callback = function()
		{
			if (hintTween != null)
				hintTween.cancel();

			hintTween = FlxTween.num(hint.alpha, 0.00001, 0.15, {ease: FlxEase.circInOut}, function(value:Float)
			{
				hint.alpha = value;
			});
		}
		hint.onOut.callback = function()
		{
			if (hintTween != null)
				hintTween.cancel();

			hintTween = FlxTween.num(hint.alpha, 0.00001, 0.2, {ease: FlxEase.circInOut}, function(value:Float)
			{
				hint.alpha = value;
			});
		}
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}
}
