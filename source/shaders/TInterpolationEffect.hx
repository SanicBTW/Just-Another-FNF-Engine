package shaders;

import flixel.graphics.tile.FlxGraphicsShader;

// T short for Texture - don t know why i ported it lol
// Done but does not replicate the same behaviour as shader toy, will look into it soon
// From https://www.shadertoy.com/view/XsfGDn

class TInterpolationEffect extends BaseEffect<TInterpolationShader>
{
	public function new()
	{
		shader = new TInterpolationShader();
	}
}

class TInterpolationShader extends FlxGraphicsShader
{
	@:glFragmentSource('

        #pragma header

        void main()
        {
            vec2 uv = floor(openfl_TextureCoordv * openfl_TextureSize) / openfl_TextureSize;
            uv = uv * openfl_TextureSize + 0.5;

            vec2 iuv = floor(uv);
            vec2 fuv = fract(uv);
            uv = iuv + fuv * fuv * (3.0 - 2.0 * fuv);
            uv = (uv - 0.5) / openfl_TextureSize;

            gl_FragColor = flixel_texture2D(bitmap, uv);
        }
    ')
	public function new()
	{
		super();
	}
}
