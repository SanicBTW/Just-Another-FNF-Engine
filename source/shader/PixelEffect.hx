package shader;

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
		shader.screen.value = [screenWidth, screenHeight];
		return value;
	}

	private function set_screenHeight(value:Float):Float
	{
		screenHeight = value;
		shader.screen.value = [screenWidth, screenHeight];
		return value;
	}

	public function new()
	{
		shader.PIXEL_FACTOR.value = [4096.];
		shader.screen.value = [flixel.FlxG.width, flixel.FlxG.height];
	}
}

class PixelShader extends Shader
{
	@:glFragmentSource('
		#pragma header

        uniform float PIXEL_FACTOR;

        void main()
        {
            vec2 size = vec2(PIXEL_FACTOR * screen.xy / screen.x);
            vec2 uv = floor(openfl_TextureCoordv * size) / size;
			vec3 col = flixel_texture2D(bitmap, uv).xyz;
            gl_FragColor = vec4(col, 1.);
        }
    ')
	public function new()
	{
		super();
	}
}
