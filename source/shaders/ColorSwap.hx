package shaders;

// Totally not https://github.com/SanicBTW/FNF-PsychEngine-0.3.2h/blob/master/source/ColorSwap.hx mixed with
// https://www.shadertoy.com/view/MsS3Wc and made an option to apply the hsv smoothing
import flixel.graphics.tile.FlxGraphicsShader;

class ColorSwap extends BaseEffect<ColorSwapShader>
{
	var hue(default, set):Float;
	var saturation(default, set):Float;
	var brightness(default, set):Float;
	var outline(default, set):Bool;
	var smoothHSV(default, set):Bool;

	@:noCompletion
	private function set_hue(value:Float)
	{
		shader.hue.value = [value];
		return hue = value;
	}

	@:noCompletion
	private function set_saturation(value:Float)
	{
		shader.saturation.value = [value];
		return saturation = value;
	}

	@:noCompletion
	private function set_brightness(value:Float)
	{
		shader.brightness.value = [value];
		return brightness = value;
	}

	@:noCompletion
	private function set_outline(value:Bool)
	{
		shader.outline.value = [value];
		return outline = value;
	}

	@:noCompletion
	private function set_smoothHSV(value:Bool)
	{
		shader.smoothHSV.value = [value];
		return smoothHSV = value;
	}

	public function new()
	{
		shader = new ColorSwapShader();
		hue = 0;
		saturation = 0;
		brightness = 0;
		outline = false;
		smoothHSV = true;
	}
}

class ColorSwapShader extends FlxGraphicsShader
{
	@:glFragmentSource('

        #pragma header

        uniform float hue;
        uniform float saturation;
        uniform float brightness;
        uniform bool outline;
        uniform bool smoothHSV;

        vec3 rgb2hsv(vec3 c)
        {
            vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);

            vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
            vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

            float d = float(q.x - min(q.w, q.y));
            float e = float(1.0e-10);

            return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }

        vec3 hsv2rgb(vec3 c)
        {
            vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);

            if (smoothHSV)
            {
                // apparently its working now?? idk if its working correctly soooo uhhhh
                vec3 rgb = 
                clamp
                (
                    abs
                    (
                        mod
                        (
                            c.xxx + K.xyz * 6.0 - K.www,
                            6.0
                        )
                        -3.0
                    )
                -1.0, 0.0, 1.0);
                rgb = rgb*rgb*(3.0-2.0*rgb);

                return c.z * mix(K.xxx, rgb, c.y);
            }
            else
            {
			    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
			    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }
        }

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

            vec4 hsv = vec4(rgb2hsv(vec3(color[0], color[1], color[2])), color[3]);
            hsv[0] += hue;
            hsv[1] += saturation;
            if (hsv[1] < 0.0)
            {
                hsv[1] = 0.0;
            }
            else if (hsv[1] > 1.0)
            {
                hsv[1] = 1.0;
            }
            hsv[2] *= 1.0 + brightness;

            color = vec4(hsv2rgb(vec3(hsv[0], hsv[1], hsv[2])), hsv[3]);

            if (outline)
			{
				vec2 size = vec2(3, 3);

				if (color.a <= 0.5) {
					float w = size.x / openfl_TextureSize.x;
					float h = size.y / openfl_TextureSize.y;
					
					if (flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x + w, openfl_TextureCoordv.y)).a != 0.
					|| flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x - w, openfl_TextureCoordv.y)).a != 0.
					|| flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y + h)).a != 0.
					|| flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y - h)).a != 0.)
						color = vec4(1.0, 1.0, 1.0, 1.0);
				}
			}
            gl_FragColor = color;
        }
    ')
	public function new()
	{
		super();
	}
}
