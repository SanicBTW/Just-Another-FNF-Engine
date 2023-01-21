package shader;

// drug effect?¿?¿?¿
class CoolShader extends Shader
{
	@:glFragmentSource("
		#pragma header

		void main()
		{
			vec2 uv = floor(openfl_TextureCoordv * openfl_TextureSize) / openfl_TextureSize;
			gl_FragColor = vec4(uv.y, 0.0, uv.x, 1.0);
			vec4 texture = flixel_texture2D(bitmap, uv);
			gl_FragColor += texture;
		}
	")
	public function new()
	{
		super();
	}
}
