package shader;

class OutlineShader extends BaseShader
{
	public function new()
	{
		glFragmentSource += '
        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            
            vec2 size = vec2(3, 3);

            if (color.a <= 0.5)
            {
                float w = size.x / openfl_TextureSize.x;
				float h = size.y / openfl_TextureSize.y;

				color = vec4(1.0, 1.0, 1.0, 1.0);
            }

            gl_FragColor = color;
        }
        ';

		super();
	}
}
