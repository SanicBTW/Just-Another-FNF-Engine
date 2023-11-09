package shaders;

import backend.SPromise;
import base.sprites.RoundedSprite;
import base.sprites.StateBG;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.math.Vector2;
import network.Request;

class ShaderTesting extends FlxState
{
	private final shaders:Array<String> = ["Pixel Shader", "Texture Interpolation", "Color Swap", "None"];
	private final properties:Map<String, Array<String>> = [
		"Pixel Shader" => ["Pixel Factor"],
		"Color Swap" => ["Hue", "Saturation", "Brightness", "Outline", "HSV Smoothing"]
	];

	private var copycat:DeepCopy;

	private var gf:PendingSprite;

	private var curEffect:BaseEffect<Dynamic>;
	private var grpOptions:FlxTypedGroup<ShaderEntry>;
	private var grpProperties:FlxTypedGroup<ShaderEntry>;

	private var curSelected(default, set):Int = 0;
	private var selectedShader:String = "";
	private var onProperties:Bool = false;

	private var curProperty(get, set):Dynamic;

	private var blockInput:Bool = false;
	private var holdTime:Float = 0;
	private var holdValue:Float = 0;
	private var holdMult:Int = 1;

	@:noCompletion
	private function set_curSelected(value:Int):Int
	{
		curSelected += value;

		var group:FlxTypedGroup<ShaderEntry> = (onProperties) ? grpProperties : grpOptions;

		if (curSelected < 0)
			curSelected = group.members.length - 1;
		if (curSelected >= group.members.length)
			curSelected = 0;

		var tf:Int = 0;

		for (entry in group.members)
		{
			entry.targetY = tf - curSelected;
			tf++;

			entry.bg.alpha = 0.15;
			entry.text.alpha = 0.45;
			entry.targetX = 1.5;
			// sizing re-allocates
			// entry.text.size = initialSize - 4;

			if (entry.targetY == 0)
			{
				entry.bg.alpha = 0.55;
				entry.text.alpha = 0.85;
				entry.targetX = 0;

				if (onProperties)
				{
					var prop:String = properties.get(selectedShader)[curSelected];
					entry.text.text = '$prop $curProperty';
				}
			}
		}

		return curSelected;
	}

	@:noCompletion
	private function get_curProperty():Dynamic
		return Reflect.getProperty(curEffect, formatProperty());

	@:noCompletion
	private function set_curProperty(value:Dynamic):Dynamic
	{
		Reflect.setProperty(curEffect, formatProperty(), value);
		curSelected = 0; // automatically refresh on change
		return curProperty;
	}

	override function create()
	{
		var bg:StateBG = new StateBG('menuBG');
		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<ShaderEntry>();
		add(grpOptions);

		grpProperties = new FlxTypedGroup<ShaderEntry>();
		add(grpProperties);

		gf = new PendingSprite(FlxG.width * 0.4, FlxG.height * 0.07, "https://storage.sancopublic.com/gfDanceTitle", (sprite) ->
		{
			FlxG.sound.playMusic(Paths.music("freshChill"));

			sprite.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
			sprite.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
			sprite.animation.play('danceLeft');
			sprite.animation.finishCallback = (ani:String) ->
			{
				if (ani == 'danceLeft')
					sprite.animation.play('danceRight');
				else
					sprite.animation.play('danceLeft');
			};

			for (i in 0...shaders.length)
			{
				var entry:ShaderEntry = new ShaderEntry(20, 320, FlxG.width - (gf.width + gf.x), shaders[i], 28);
				entry.text.autoSize = false;
				entry.text.color = FlxColor.WHITE;
				entry.text.font = Paths.font("open_sans.ttf");
				entry.text.alignment = LEFT;
				entry.targetY = i;
				grpOptions.add(entry);
			}

			curSelected = grpOptions.length + 1;
		});
		add(gf);

		super.create();
	}

	override function onActionPressed(action:String)
	{
		if (blockInput)
			return;

		switch (action)
		{
			case "ui_up":
				curSelected = -1;
				if (onProperties)
					holdValue = curProperty;
			case "ui_down":
				curSelected = 1;
				if (onProperties)
					holdValue = curProperty;

			case "confirm":
				if (onProperties)
				{
					// easy enough lmfao
					if (curProperty is Bool)
						curProperty = !curProperty;
				}
				else
				{
					var openProperties:Bool = selectedShader == shaders[curSelected];
					if (openProperties)
					{
						regenProperties();
						return;
					}

					switch (curSelected)
					{
						case 0: // Pixel
							curEffect = new PixelEffect();
							gf.shader = curEffect.shader;

						case 1: // Better Texture Interpolation
							curEffect = new TInterpolationEffect();
							gf.shader = curEffect.shader;

						case 2: // ColorSwap
							curEffect = new ColorSwap();
							gf.shader = curEffect.shader;

						case 3: // None;
							gf.shader = null;
					}

					selectedShader = shaders[curSelected];
					copycat = new DeepCopy(curEffect, ["shader", "screenWidth", "screenHeight", "elapsed", "tick"]);
				}

			case "reset":
				if (onProperties)
				{
					copycat.analyzeChanges(curEffect);
					copycat.revertField(curEffect, formatProperty());
					curSelected = 0; // as this aint curProperty getter or setter and modifies it through reflect, gotta force refreshing by ourselves
					// should reset these too jus in case
					holdTime = 0;
					holdValue = curProperty;
				}

			case "back":
				// brhuhhhhbbb
				if (onProperties)
				{
					onProperties = false;
					regenProperties(true);
				}

				curSelected = grpOptions.length + 1;
		}
	}

	override function onActionReleased(action:String)
	{
		blockInput = false;
	}

	override function update(elapsed:Float)
	{
		// no booleans my guy (couldnt you just do is Float than !is Bool ????)
		if (onProperties && !(curProperty is Bool))
		{
			if (controls.ui_left.state == PRESSED || controls.ui_right.state == PRESSED)
			{
				holdMult = (controls.ui_left.state == PRESSED) ? -1 : 1;
				if (FlxG.keys.pressed.SHIFT)
					holdMult = (controls.ui_left.state == PRESSED) ? -10 : 10;

				if (holdTime > 0.5)
				{
					holdValue += 1 * elapsed * holdMult;
					curProperty = FlxMath.roundDecimal(holdValue, 2);
				}

				holdTime += elapsed;
			}
			else if (controls.ui_left.state == RELEASED || controls.ui_right.state == RELEASED)
				holdTime = 0;
		}

		super.update(elapsed);
	}

	function regenProperties(forceClean:Bool = false)
	{
		blockInput = true;

		var properties:Null<Array<String>> = properties.get(selectedShader);
		if (properties == null || forceClean)
		{
			for (i in 0...grpProperties.members.length)
			{
				grpProperties.remove(grpProperties.members[0], true);
			}
			onProperties = false;
		}
		else
		{
			for (i in 0...properties.length)
			{
				var entry:ShaderEntry = new ShaderEntry(340, 320, FlxG.width / 2, properties[i], 28);
				entry.text.autoSize = false;
				entry.text.disableCaching = true;
				entry.text.color = FlxColor.WHITE;
				entry.text.font = Paths.font("open_sans.ttf");
				entry.text.alignment = LEFT;
				entry.targetY = i;
				grpProperties.add(entry);
			}
			holdValue = curProperty;
			onProperties = true;
			curSelected = grpProperties.length + 1;
		}
	}

	function formatProperty()
	{
		var prop:String = properties.get(selectedShader)[curSelected];
		return switch (selectedShader)
		{
			case "Pixel Shader":
				"PIXEL_FACTOR";

			case "Color Swap":
				return switch (prop)
				{
					case "Hue":
						"hue";

					case "Saturation":
						"saturation";

					case "Brightness":
						"brightness";

					case "Outline":
						"outline";

					case "HSV Smoothing":
						"smoothHSV";

					case _:
						"";
				};

			case _:
				"";
		}
	}
}

class PendingSprite extends FlxSprite
{
	private var spriteSheetXML:Null<String>;
	private var spriteSheetGR:Null<FlxGraphic>;

	private var then:FlxSprite->Void;
	private var fired:Bool = false;

	override public function new(?X:Float = 0, ?Y:Float = 0, LoadURL:String, then:FlxSprite->Void)
	{
		super(X, Y);

		// make a transparent graphic to avoid having the default flixel graphic
		makeGraphic(1, 1, FlxColor.TRANSPARENT);

		this.then = then;

		new Request<String>({url: '${LoadURL}.xml', type: STRING}).then((xml:String) ->
		{
			spriteSheetXML = xml;
		});

		new Request<FlxGraphic>({url: '${LoadURL}.png', type: IMAGE}).then((lgraphic:FlxGraphic) ->
		{
			spriteSheetGR = lgraphic;
		});
	}

	override public function update(elapsed:Float)
	{
		if (!fired && spriteSheetGR != null && spriteSheetXML != null)
		{
			frames = FlxAtlasFrames.fromSparrow(spriteSheetGR, spriteSheetXML);

			then(this);
			fired = true;
		}

		super.update(elapsed);
	}
}

// joins flxtext and rounded sprite, not using lerped flx text or modifying it cuz it already works so im leavin it as it is just in case, but this is heavily based off it so
class ShaderEntry extends FlxSpriteGroup
{
	public var bg:RoundedSprite;
	public var text:FlxText;

	public var targetX:Float = 0;
	public var targetY:Float = 0;
	public var initialPositions:Vector2 = new Vector2(0, 0);
	public var defaultText:String = "";

	override public function new(X:Float, Y:Float, FieldWidth:Float, Text:String, Size:Int)
	{
		super(X, Y);

		initialPositions.setTo(X, Y);
		defaultText = Text;

		text = new FlxText(12.5, 12.5, FieldWidth, Text, Size, true);
		bg = new RoundedSprite(0, 0, Math.floor(text.width + 25), Math.floor(text.height + 25), [50], FlxColor.BLACK, 0.75);

		add(bg);
		add(text);
	}

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = FlxMath.bound(elapsed * 9.6, 0, 1);
		x = FlxMath.lerp(x, (targetX * text.size / 2) + initialPositions.x, lerpVal);
		y = FlxMath.lerp(y, (targetY * 1.3 * height) + initialPositions.y, lerpVal);

		// force
		if (targetY != 0 && text.text != defaultText)
			text.text = defaultText;

		super.update(elapsed);
	}
}

// not cookin no more :speaking_head: :fire:
// should i keep reference of the object?
class DeepCopy
{
	private var defaultFields:Array<String> = [];
	private var _defaultValues:Map<String, Dynamic> = new Map();

	private var modifiedFields:Array<String> = [];
	private var _modifiedValues:Map<String, Dynamic> = new Map();

	private var _exclusions:Array<String> = [];

	public function new(o:Dynamic, exclusions:Array<String>)
	{
		_exclusions = exclusions;

		defaultFields = Reflect.fields(o);
		for (field in defaultFields)
		{
			if (exclusions.indexOf(field) > -1)
				continue; // skip

			_defaultValues.set(field, Reflect.getProperty(o, field));
		}
	}

	public function analyzeChanges(o:Dynamic)
	{
		// run again the constructor behaviour but only add modified fields n values
		for (field in defaultFields)
		{
			if (_exclusions.indexOf(field) > -1)
				continue; // skip

			var defValue:Dynamic = _defaultValues.get(field);
			// check again the fields of the object
			var newVal:Dynamic = Reflect.getProperty(o, field);

			if (defValue != newVal)
			{
				trace('Modified $field with $newVal (default $defValue)');
				modifiedFields.push(field);
				_modifiedValues.set(field, newVal);
			}
		}
	}

	public function revertField(o:Dynamic, field:String)
	{
		if (modifiedFields.indexOf(field) > -1) // found in the array
		{
			trace('Reverting $field (${_modifiedValues.get(field)}) to ${_defaultValues.get(field)}');
			Reflect.setProperty(o, field, _defaultValues.get(field));
		}
	}
}
