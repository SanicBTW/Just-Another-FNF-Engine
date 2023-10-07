package shaders;

import flixel.graphics.tile.FlxGraphicsShader;

class PixelEffect extends BaseEffect<PixelShader>
{
	var PIXEL_FACTOR(default, set):Float;

	@:noCompletion
	private function set_PIXEL_FACTOR(value:Float):Float
	{
		shader.PIXEL_FACTOR.value = [value];
		return PIXEL_FACTOR = value;
	}

	public function new()
	{
		shader = new PixelShader();
		PIXEL_FACTOR = 2048.;
	}
}

// Should base the size of the uv by the texture size and NOT from the screen
class PixelShader extends FlxGraphicsShader
{
	@:glFragmentSource('

        #pragma header

        uniform float PIXEL_FACTOR;

        void main()
        {
            vec2 size = vec2(PIXEL_FACTOR * openfl_TextureSize.xy / openfl_TextureSize.x);
            vec2 uv = floor(openfl_TextureCoordv * size) / size;
            gl_FragColor = flixel_texture2D(bitmap, uv);
        }

    ')
	public function new()
	{
		super();
	}
}
