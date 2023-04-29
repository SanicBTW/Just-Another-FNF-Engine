package funkin.components;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.Assets;

// TODO: Grab the icon from the characters path
class HealthIcon extends FlxSprite
{
	private var character:String = '';
	private var isPlayer:Bool = false;

	private var iconOffsets:Array<Float> = [0, 0];

	public function new(char:String = 'bf-old', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		scrollFactor.set();
		changeIcon(char);
	}

	public function changeIcon(char:String)
	{
		if (this.character != char)
		{
			// Loading graphic
			var graphic:FlxGraphic = Paths.image(getPath(char));
			// loading 2 times apparently gets the size of it dunno
			loadGraphic(graphic);
			loadGraphic(graphic, true, Math.floor(width / 2), Math.floor(height));
			iconOffsets[0] = (width - 150) / 2;
			iconOffsets[1] = (width - 150) / 2;
			updateHitbox();

			// Setting up animations
			animation.add(char, [0, 1], 0, false, isPlayer);
			animation.play(char);
			this.character = char;
			antialiasing = SaveData.antialiasing;
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	private function getPath(char:String)
	{
		var name:String = 'icons/$char';
		if (!Assets.exists(Paths.getPath('images/$name.png')))
			name = 'icons/icon-$char';
		if (!Assets.exists(Paths.getPath('images/$name.png')))
			name = 'icons/icon-face';

		return name;
	}
}
