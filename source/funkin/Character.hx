package funkin;

import backend.IO;
import backend.ScriptHandler.ForeverModule;
import backend.ScriptHandler;
import base.Conductor;
import base.sprites.OffsettedSprite;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.ds.StringMap;
import haxe.io.Path;
import openfl.utils.Assets;

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

// Just the old code
class Character extends OffsettedSprite
{
	// If not found it will try to get this one
	private static final DEFAULT:String = "bf";

	// Final character file extension
	private var extension:String = ".json";

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT;

	// Singing and beat shit
	public var holdTimer:Float = 0;
	public var singDuration:Float = 4;
	public var danceEveryNumBeats:Int = 2;

	// GF Dance shit
	public var danceIdle:Bool = false;
	public var danced:Bool = false;

	// Positions
	public var cameraPosition:FlxPoint;
	public var characterPosition:FlxPoint;

	// Health
	public var healthIcon:String = 'bf';
	public var healthColor:FlxColor;

	public var startedDeath:Bool = false;
	public var hasMissAnimations:Bool = false;

	// Misc
	public var colorTween:FlxTween;
	public var stunned:Bool = false;

	public function new(X:Float, Y:Float, isPlayer:Bool = false, character:String = 'bf')
	{
		super(X, Y);
		cameraPosition = new FlxPoint(0, 0);
		characterPosition = new FlxPoint(0, 0);

		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = true;

		var charPath:String = getCharPath();
		trace(charPath);

		switch (extension)
		{
			case ".json":
				{
					var json:CharacterFile = cast haxe.Json.parse(Paths.text(charPath));
					frames = Paths.getSparrowAtlas(json.image.replace("characters/", ""), 'characters/$curCharacter');

					if (json.scale != 1)
					{
						setGraphicSize(Std.int(width * json.scale));
						updateHitbox();
					}

					healthIcon = json.healthicon;
					singDuration = json.sing_duration;
					characterPosition.set(json.position[0], json.position[1]);
					cameraPosition.set(json.camera_position[0], json.camera_position[1]);
					flipX = !!json.flip_x;

					if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
						healthColor = FlxColor.fromRGB(json.healthbar_colors[0], json.healthbar_colors[1], json.healthbar_colors[2]);

					if (json.no_antialiasing)
						antialiasing = false;

					if (json.animations != null && json.animations.length > 0)
					{
						for (anim in json.animations)
						{
							var animAnim:String = anim.anim;
							var animName:String = anim.name;
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
				}
			case ".hxs":
				{
					var exposure:StringMap<Dynamic> = new StringMap<Dynamic>();
					exposure.set('character', this);
					var charModule:ForeverModule = ScriptHandler.loadModule(character, 'characters/$character', exposure, DEFAULT);
					if (charModule.exists('loadAnimations'))
						charModule.get('loadAnimations')();
				}
		}

		danceIdle = (animation.getByName('danceLeft') != null && animation.getByName('danceRight') != null);
		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;
		dance();

		if (isPlayer)
			flipX = !flipX;

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

				if (holdTimer >= Conductor.stepCrochet * (singDuration / 1000))
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

				if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished)
					dance();

				if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished && startedDeath)
					playAnim('deathLoop');
			}
		}

		super.update(elapsed);
	}

	public function dance(forced:Bool = true)
	{
		if (danceIdle)
		{
			danced = !danced;

			playAnim('dance${danced ? 'Right' : 'Left'}', forced);
		}
		else
			playAnim('idle', forced);
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		super.playAnim(AnimName, Force, Reversed, Frame);

		if (curCharacter.startsWith("gf"))
		{
			if (AnimName == "singLEFT")
				danced = true;

			if (AnimName == "singRIGHT")
				danced = false;

			if (AnimName == "singUP" || AnimName == "singDOWN")
				danced = !danced;
		}
	}

	private function getCharPath():String
	{
		var retPath:String = Paths.getPath('characters/$curCharacter/$curCharacter.hxs', TEXT);
		if (Assets.exists(retPath))
		{
			extension = '.hxs';
			return retPath;
		}
		else
		{
			retPath = Path.join([IO.getFolderPath(CHARACTERS), '$curCharacter/$curCharacter.hxs']);
			if (IO.exists(retPath))
			{
				extension = '.hxs';
				return retPath;
			}
		}

		retPath = Paths.getPath('characters/$curCharacter/$curCharacter.json', TEXT);
		if (Assets.exists(retPath))
		{
			extension = '.json';
			return retPath;
		}
		else
		{
			retPath = Path.join([IO.getFolderPath(CHARACTERS), '$curCharacter/$curCharacter.json']);
			if (IO.exists(retPath))
			{
				extension = '.json';
				return retPath;
			}
		}

		retPath = Paths.getPath('characters/$DEFAULT/$DEFAULT.json', TEXT);
		curCharacter = DEFAULT;
		extension = '.json';

		return retPath;
	}
}
