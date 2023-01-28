package shader;

class ChromaticAbberationShader extends Shader
{
	@:glFragmentSource('
        #pragma header

        float hash(in float n) { return fract(sin(n) * 43758.5453123); }

        void main()
        {
            vec2 uv = floor(openfl_TextureCoordv * openfl_TextureSize) / openfl_TextureSize;
            vec3 col = flixel_texture2D(bitmap, uv).xyz;

            float noise = hash((hash(openfl_TextureCoordv.x) + openfl_TextureCoordv.y) * elapsed) * .055;

            gl_FragColor = vec4(col + noise, 1.);
        }
    ')
	public function new()
	{
		super();
		this.elapsed.value = [flixel.FlxG.elapsed];
	}
}
