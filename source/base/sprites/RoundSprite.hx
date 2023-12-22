package base.sprites;

import flixel.addons.display.shapes.FlxShape;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.geom.Matrix;

class RoundSprite extends FlxShape
{
	public var topLeftRadius(default, set):Float;

	@:noCompletion
	private function set_topLeftRadius(newRad:Float):Float
	{
		topLeftRadius = newRad;
		shapeDirty = true;
		return newRad;
	}

	public var topRightRadius(default, set):Float;

	@:noCompletion
	private function set_topRightRadius(newRad:Float):Float
	{
		topRightRadius = newRad;
		shapeDirty = true;
		return newRad;
	}

	public var botLeftRadius(default, set):Float;

	@:noCompletion
	private function set_botLeftRadius(newRad:Float):Float
	{
		botLeftRadius = newRad;
		shapeDirty = true;
		return newRad;
	}

	public var botRightRadius(default, set):Float;

	@:noCompletion
	private function set_botRightRadius(newRad:Float):Float
	{
		botRightRadius = newRad;
		shapeDirty = true;
		return newRad;
	}

	public function new(X:Float, Y:Float, Width:Float, Height:Float, CornerRadius:Array<Float>, Color:FlxColor)
	{
		super(X, Y, 0, 0, {
			thickness: 0,
			color: FlxColor.TRANSPARENT
		}, Color, Width, Height);

		shape_id = ROUNDED_BOX;

		// should parse better (eg: topLeft: 5, topRight: 15, null, null) - assign the 2 existing values to each corner
		if (CornerRadius.length < 3)
			topLeftRadius = topRightRadius = botLeftRadius = botRightRadius = CornerRadius[0];
		else
		{
			topLeftRadius = CornerRadius[0];
			topRightRadius = CornerRadius[1];
			botLeftRadius = CornerRadius[2];
			botRightRadius = CornerRadius[3];
		}
	}

	override public function drawSpecificShape(?matrix:Matrix)
	{
		// still a box
		var rectPos:Float = (lineStyle.thickness / 2);

		FlxSpriteUtil.drawRoundRectComplex(this, rectPos, rectPos, shapeWidth, shapeHeight, topLeftRadius, topRightRadius, botLeftRadius, botRightRadius,
			fillColor, lineStyle, {
				matrix: matrix
			});
	}
}
