package shaders;

import flixel.graphics.tile.FlxGraphicsShader;

// T short for Texture - don t know why i ported it lol
// From https://www.shadertoy.com/view/XsfGDn

class TInterpolationEffect extends BaseEffect<TInterpolationShader> {}

class TInterpolationShader extends FlxGraphicsShader
{
	@:glFragmentSource('

        #pragma header

        vec4 improveTexture(sampler2D sam, vec2 uv)
        {
            float texRes = float(textureSize(sam, 0).x);
            uv = uv * texRes + 0.5;
            vec2 iuv = floor(uv);
            vec2 fuv = fract(uv);
            uv = iuv + fuv * fuv * (3.0-2.0*fuv);
            uv = (uv - 0.5) / texRes;
            return flixel_texture2D(sam, uv);
        }

        void main()
        {
            vec2 size = vec2(openfl_TextureCoordv * openfl_TextureSize.xy / openfl_TextureSize.x);
            vec2 uv = floor(openfl_TextureCoordv * size) / size;

            vec3 colA = flixel_texture2D(bitmap, uv).xyz;
            vec3 colB = improveTexture(bitmap, uv).xyz;

            float f = sin(3.1415927 * size.x + 0.7 * tick);
            vec3 col = (f .>= 0.0) ? colA : colB;
            col *= smoothstep(0.0, 0.01, abs(f - 0.0));
            gl_fragColor = flixel_texture2D(col, uv);
        }
    ')
	public function new()
	{
		super();
	}
}
