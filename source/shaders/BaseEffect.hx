package shaders;

import flixel.graphics.tile.FlxGraphicsShader;

@:publicFields
// TODO: Rename it to something better or move the code to FlxGraphicsShader lol
class BaseEffect<T:FlxGraphicsShader>
{
	var shader(default, null):T;

	var screenWidth(default, set):Float;

	@:noCompletion
	private function set_screenWidth(value:Float):Float
	{
		shader.screen.value = [value, screenHeight];
		return screenWidth = value;
	}

	var screenHeight(default, set):Float;

	@:noCompletion
	private function set_screenHeight(value:Float):Float
	{
		shader.screen.value = [screenWidth, value];
		return screenHeight = value;
	}

	var elapsed(default, set):Float;

	@:noCompletion
	private function set_elapsed(value:Float):Float
	{
		shader.elapsed.value = [value];
		return elapsed = value;
	}

	var tick(default, set):Float;

	@:noCompletion
	private function set_tick(value:Float):Float
	{
		shader.tick.value = [value];
		return tick = value;
	}
}
