package funkin.components;

import base.ui.Bar;
import base.ui.Sprite.AttachedSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

@:allow(funkin.ui.UI)
class HealthTracker extends FlxSpriteGroup
{
	private var healthBarBG:AttachedSprite;
	private var healthBar:Bar;

	// I'll just call it p1 and p2 instead of player and opponent
	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;

	public function new(X:Float, Y:Float, player:Character, opponent:Character)
	{
		super(X, Y);

		antialiasing = SaveData.antialiasing;
		scrollFactor.set();

		healthBarBG = new AttachedSprite('ui/healthBar');
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;

		healthBar = new Bar(healthBarBG.x + 4, healthBarBG.y + 4, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), opponent.healthColor,
			player.healthColor);
		healthBar.flipX = true;
		healthBar.screenCenter(flixel.util.FlxAxes.X);
		healthBar.scrollFactor.set();
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(player.healthIcon, player.isPlayer);
		iconP1.y = healthBar.y - (iconP1.height / 2);

		iconP2 = new HealthIcon(opponent.healthIcon, opponent.isPlayer);
		iconP2.y = healthBar.y - (iconP2.height / 2);

		add(healthBarBG);
		add(healthBar);
		add(iconP1);
		add(iconP2);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		healthBar.value = (Timings.health / 2);

		var iconLerp:Float = CoolUtil.boundTo(1 - (elapsed * 9), 0, 1);
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, iconLerp);
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, iconLerp);
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		flixel.FlxG.watch.addQuick('health perc', healthBar.percent);
	}

	public function beatHit()
	{
		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();
	}
}
