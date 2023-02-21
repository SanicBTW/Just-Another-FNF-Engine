package funkin;

// got lazy so everything from here is just psych shit lol, improve, do custom and add flxanimate support
import base.Conductor;
import base.SaveData;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import openfl.Assets;

using StringTools;

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	private static final DEFAULT:String = "bf";

	public var animOffsets:Map<String, Array<Dynamic>>;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT;

	public var holdTimer:Float = 0;
	public var singDuration:Float = 4;
	public var danceEveryNumBeats:Int = 2;

	// GF Dance shit
	public var danceIdle:Bool = false;
	public var danced:Bool = false;

	public var cameraPosition:FlxPoint;
	public var characterPosition:FlxPoint;

	public function new(x:Float, y:Float, isPlayer:Bool = false, character:String = 'bf')
	{
		super(x, y);
		antialiasing = SaveData.antialiasing;
		this.isPlayer = isPlayer;
		setChar(x, y, character);
	}

	// create it on new
	public function setChar(x:Float, y:Float, character:String = 'bf')
	{
		animOffsets = new Map();
		cameraPosition = new FlxPoint(0, 0);
		characterPosition = new FlxPoint(0, 0);

		curCharacter = character;

		var json:CharacterFile = cast haxe.Json.parse(Assets.getText(getCharPath()));
		frames = Paths.getForcedSparrowAtlas(curCharacter + "/" + json.image.replace("characters/", ""), "characters");

		if (json.scale != 1)
		{
			setGraphicSize(Std.int(width * json.scale));
			updateHitbox();
		}

		characterPosition.set(json.position[0], json.position[1]);
		cameraPosition = new FlxPoint(json.camera_position[0], json.camera_position[1]);
		singDuration = json.sing_duration;
		flipX = json.flip_x;
		if (json.no_antialiasing)
			antialiasing = false;

		if (json.animations != null && json.animations.length > 0)
		{
			for (anim in json.animations)
			{
				var animAnim:String = '${anim.anim}';
				var animName:String = '${anim.name}';
				var animFPS:Int = anim.fps;
				var animLoop:Bool = !!anim.loop;
				var animInd:Array<Int> = anim.indices;
				if (animInd != null && animInd.length > 0)
					animation.addByIndices(animAnim, animName, animInd, "", animFPS, animLoop);
				else
					animation.addByPrefix(animAnim, animName, animFPS, animLoop);

				if (anim.offsets != null && anim.offsets.length > 1)
					animOffsets[animAnim] = [anim.offsets[0], anim.offsets[1]];
			}
		}

		if (isPlayer)
			flipX = !flipX;

		danceIdle = (animation.getByName('danceLeft') != null && animation.getByName('danceRight') != null);
		dance();

		setPosition(x, y);
		this.x += characterPosition.x;
		this.y += characterPosition.y;
	}

	override public function update(elapsed:Float)
	{
		if (animation.curAnim != null)
		{
			if (!isPlayer)
			{
				if (animation.curAnim.name.startsWith("sing"))
					holdTimer += elapsed;

				if (holdTimer >= (Conductor.stepCrochet * singDuration) / 1000)
				{
					dance();
					holdTimer = 0;
				}
			}
			else
			{
				if (animation.curAnim.name.startsWith("sing"))
					holdTimer += elapsed;
				else
					holdTimer = 0;
			}
		}

		super.update(elapsed);
	}

	public function dance(forced:Bool = false)
	{
		if (danceIdle)
		{
			danced = !danced;

			playAnim('dance${danced ? 'Right' : 'Left'}', forced);
		}
		else
			playAnim('idle', forced);
	}

	// todo: improve
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		animation.play(AnimName, Force, Reversed, Frame);

		if (animOffsets.exists(AnimName))
			offset.set(animOffsets[AnimName][0], animOffsets[AnimName][1]);
		else
			offset.set(0, 0);
	}

	private function getCharPath():String
	{
		var retPath:String = Paths.getLibraryPath('$curCharacter/$curCharacter.json', "characters");
		if (!Assets.exists(retPath))
			retPath = Paths.getLibraryPath('$DEFAULT/$DEFAULT.json', "characters");

		return retPath;
	}
}
