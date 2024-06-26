package funkin;

import backend.Cache;
import backend.Conductor;
import backend.IO;
import backend.SPromise;
import backend.Save;
import backend.io.Path;
import backend.scripting.*;
import base.sprites.OffsettedSprite;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.Json;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import openfl.utils.Assets;
import openfl.utils.ByteArray;

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

typedef VirtCharact =
{
	var image:Bytes;
	var xml:String;
	var json:String;
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

	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;

	// GF Dance shit
	public var danceIdle:Bool = false;
	public var danced:Bool = false;

	// Positions
	public var cameraPosition:FlxPoint;
	public var characterPosition:FlxPoint;

	// Health
	public var healthIcon:String = 'bf';
	public var healthColor:FlxColor;

	public var dead:Bool = false;
	public var startedDeath:Bool = false;
	public var hasMissAnimations:Bool = false;

	// Misc
	public var colorTween:FlxTween;
	public var stunned:Bool = false;
	public var alreadyLoaded:Bool = true;

	public function new(X:Float, Y:Float, isPlayer:Bool = false, character:String = 'bf', overrideLoad:Bool = false)
	{
		super(X, Y);
		cameraPosition = new FlxPoint(0, 0);
		characterPosition = new FlxPoint(0, 0);

		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = true;

		if (overrideLoad)
			return;

		var charPath:String = getCharPath();

		switch (extension)
		{
			// smart ass parsing (i want to kms)
			case ".json":
				{
					var isFS:Bool = Cache.fromFS(charPath);

					charPath = charPath.substring(0, charPath.lastIndexOf("/"));

					// ayo using this is actually really smart ngl
					var isolatedPaths:IsolatedPaths = new IsolatedPaths(charPath);
					var json:CharacterFile = cast haxe.Json.parse(Cache.getText('$charPath/$curCharacter$extension'));

					if (!isFS)
					{
						if (charPath.contains(":"))
						{
							var lib:String = charPath.split(":")[0];
							charPath = charPath.replace('$lib:', "");
							charPath = charPath.substring(charPath.indexOf(lib) + lib.length + 1);
						}

						// change the local path to the new parsed one (kind of uhhhhhhhhhhhhhhhhhhhhhhhhhhh)
						@:privateAccess
						isolatedPaths.localPath = charPath;
					}

					frames = isolatedPaths.getSparrowAtlas(json.image.replace("characters/", ""));

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
			if (heyTimer > 0)
			{
				heyTimer -= elapsed;
				if (heyTimer <= 0)
				{
					if (specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			}
			else if (specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

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
		if (!specialAnim)
		{
			if (danceIdle)
			{
				danced = !danced;

				playAnim('dance${danced ? 'Right' : 'Left'}', forced);
			}
			else
				playAnim('idle', forced);
		}
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		specialAnim = false;
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

	// goofy - lets prioritize filesystem before assets (why didnt we do this already??)
	private function getCharPath():String
	{
		var retPath:String = Path.join(IO.getFolderPath(CHARACTERS), '$curCharacter/$curCharacter.hxs');
		if (IO.exists(retPath))
		{
			extension = '.hxs';
			return retPath;
		}
		else
		{
			retPath = Paths.file('characters/$curCharacter/$curCharacter.hxs');
			if (Assets.exists(retPath))
			{
				extension = '.hxs';
				return retPath;
			}
		}

		retPath = Path.join(IO.getFolderPath(CHARACTERS), '$curCharacter/$curCharacter.json');
		if (IO.exists(retPath))
		{
			extension = '.json';
			return retPath;
		}
		else
		{
			retPath = Paths.file('characters/$curCharacter/$curCharacter.json');
			if (Assets.exists(retPath))
			{
				extension = '.json';
				return retPath;
			}
		}

		retPath = Paths.file('characters/$DEFAULT/$DEFAULT.json');
		curCharacter = DEFAULT;
		extension = '.json';

		return retPath;
	}

	public static function loadFromVFS(isPlayer:Bool = false, character:String):SPromise<Character>
	{
		return new SPromise<Character>((resolve, reject) ->
		{
			Save.database.get(VFS, 'character:$character').then((s) ->
			{
				if (s == null)
				{
					resolve(new Character(0, 0, isPlayer, character));
					return;
				}

				var save:VirtCharact = cast s;

				#if !js
				var byteArray:ByteArray = ByteArray.fromBytes(save.image);
				#else
				@:privateAccess
				var byteArray:ByteArray = ByteArray.fromArrayBuffer(save.image.b.buffer);
				#end

				var char:Character = new Character(0, 0, isPlayer, "", true);

				openfl.display.BitmapData.loadFromBytes(byteArray).onComplete((bitmapData) ->
				{
					char.frames = flixel.graphics.frames.FlxAtlasFrames.fromSparrow(flixel.graphics.FlxGraphic.fromBitmapData(bitmapData), save.xml);

					var json:CharacterFile = Json.parse(save.json);
					if (json.scale != 1)
					{
						char.setGraphicSize(Std.int(char.width * json.scale));
						char.updateHitbox();
					}

					char.healthIcon = json.healthicon;
					char.singDuration = json.sing_duration;
					char.characterPosition.set(json.position[0], json.position[1]);
					char.cameraPosition.set(json.camera_position[0], json.camera_position[1]);
					char.flipX = !!json.flip_x;

					if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
						char.healthColor = FlxColor.fromRGB(json.healthbar_colors[0], json.healthbar_colors[1], json.healthbar_colors[2]);

					if (json.no_antialiasing)
						char.antialiasing = false;

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
								char.animation.addByIndices(animAnim, animName, animInd, "", animFPS, animLoop);
							else
								char.animation.addByPrefix(animAnim, animName, animFPS, animLoop);

							if (anim.offsets != null && anim.offsets.length > 1)
								char.animOffsets[animAnim] = [anim.offsets[0], anim.offsets[1]];
						}
					}

					char.danceIdle = (char.animation.getByName('danceLeft') != null && char.animation.getByName('danceRight') != null);
					if (char.animOffsets.exists('singLEFTmiss')
						|| char.animOffsets.exists('singDOWNmiss')
						|| char.animOffsets.exists('singUPmiss')
						|| char.animOffsets.exists('singRIGHTmiss'))
						char.hasMissAnimations = true;
					char.dance();

					if (isPlayer)
						char.flipX = !char.flipX;

					char.x += char.characterPosition.x;
					char.y += char.characterPosition.y;

					resolve(char);
				});
			});
		});
	}
}
