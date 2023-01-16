package shader;

import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;

class PixelEffect
{
	public var shader(default, null):PixelShader = new PixelShader();
	public var PIXEL_FACTOR(default, set):Float;
	public var screenWidth(default, set):Float;
	public var screenHeight(default, set):Float;

	private function set_PIXEL_FACTOR(value:Float):Float
	{
		PIXEL_FACTOR = value;
		shader.PIXEL_FACTOR.value = [PIXEL_FACTOR];
		return value;
	}

	private function set_screenWidth(value:Float):Float
	{
		screenWidth = value;
		shader.screenWidth.value = [screenWidth];
		return value;
	}

	private function set_screenHeight(value:Float):Float
	{
		screenHeight = value;
		shader.screenHeight.value = [screenHeight];
		return value;
	}

	public function new()
	{
		shader.PIXEL_FACTOR.value = [0.0];
		shader.screenWidth.value = [FlxG.width];
		shader.screenHeight.value = [FlxG.height];
	}
}

class PixelShader extends FlxShader
{
	@:glFragmentSource('
		varying float openfl_Alphav; 
		varying vec4 openfl_ColorMultiplierv; 
		varying vec4 openfl_ColorOffsetv; 
		varying vec2 openfl_TextureCoordv; 
		uniform bool openfl_HasColorTransform; 
		uniform vec2 openfl_TextureSize; 
		uniform sampler2D bitmap; 
		uniform bool hasTransform; 
		uniform bool hasColorTransform; 

		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) 
		{
			vec4 color = texture2D(bitmap, coord);
			if (!hasTransform)
			{
				return color;
			}

			if (color.a == 0.0)
			{
				return vec4(0.0, 0.0, 0.0, 0.0);
			}

			if (!hasColorTransform)
			{
				return color * openfl_Alphav;
			}

			color = vec4(color.rgb / color.a, color.a);

			mat4 colorMultiplier = mat4(0);
			colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
			colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
			colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
			colorMultiplier[3][3] = openfl_ColorMultiplierv.w;

			color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);

			if (color.a > 0.0)
			{
				return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
			}

			return vec4(0.0, 0.0, 0.0, 0.0);
		}

        uniform float PIXEL_FACTOR;
        uniform float screenWidth;
        uniform float screenHeight;

        void main()
        {
            vec2 size = PIXEL_FACTOR * (screenWidth + screenHeight) / screenWidth;
            vec2 uv = floor(openfl_TextureCoordv * size) / size;
            vec3 col = flixel_texture2D(bitmap, uv).xyz;
            gl_FragColor = vec4(col, 1.);
        }
    ')
	@:glVertexSource('
		attribute float openfl_Alpha;
		attribute vec4 openfl_ColorMultiplier;
		attribute vec4 openfl_ColorOffset;
		attribute vec4 openfl_Position;
		attribute vec2 openfl_TextureCoord;

		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform mat4 openfl_Matrix;
		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;

		attribute float alpha;
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		uniform bool hasColorTransform;
		
		void main(void)
		{
			openfl_Alphav = openfl_Alpha;
			openfl_TextureCoordv = openfl_TextureCoord;

			if (openfl_HasColorTransform) {
				openfl_ColorMultiplierv = openfl_ColorMultiplier;
				openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
			}

			gl_Position = openfl_Matrix * openfl_Position;

			openfl_Alphav = openfl_Alpha * alpha;
			if (hasColorTransform)
			{
				openfl_ColorOffsetv = colorOffset / 255.0;
				openfl_ColorMultiplierv = colorMultiplier;
			}
		}
	')
	public function new()
	{
		super();
	}
}
