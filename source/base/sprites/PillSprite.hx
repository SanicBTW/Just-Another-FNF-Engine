package base.sprites;

import flixel.addons.display.shapes.FlxShape;
import flixel.addons.display.shapes.FlxShapeType;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.geom.Matrix;

class PillSprite extends FlxShape
{
	public function new(X:Float, Y:Float, Width:Float, Height:Float, Color:FlxColor)
	{
		super(X, Y, 0, 0, {
			thickness: 0,
			color: FlxColor.TRANSPARENT,
		}, Color, Width, Height);

		shape_id = FlxShapeType.PILL;
	}

	private function getPos(axis:FlxAxes)
	{
		var mid = getGraphicMidpoint();

		if (axis == X)
			return mid.x - x;
		if (axis == Y)
			return mid.y - y;
		if (axis == XY)
			return 0;

		mid.put();

		return 0;
	}

	override public function drawSpecificShape(?matrix:Matrix):Void
	{
		// For proper rounding
		var minusVal:Float = Math.min(shapeWidth, shapeHeight);
		var rad:Float = (minusVal / 2) - (lineStyle.thickness / 2);

		// Proper positioning from FlxShapeBox
		var rectPos:Float = (lineStyle.thickness / 2);

		// because sometimes it looks weird
		// 0.25 looks decent lets go with it
		var midY:Float = getPos(Y) - 0.25;

		FlxSpriteUtil.drawCircle(this, rectPos + rad, midY, rad, fillColor, lineStyle, {matrix: matrix});
		FlxSpriteUtil.drawCircle(this, (rectPos + shapeWidth) - rad, midY, rad, fillColor, lineStyle, {matrix: matrix});
		FlxSpriteUtil.drawRect(this, rectPos + rad, rectPos, shapeWidth - (2 * rad), shapeHeight, fillColor, lineStyle, {matrix: matrix});
	}
}
