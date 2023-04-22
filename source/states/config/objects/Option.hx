package states.config.objects;

// wacky shit, stole some shit from Psych Option, might need to rewrite it or smth bruh
class Option extends flixel.group.FlxSpriteGroup
{
	// Graphics
	private var _bg:flixel.FlxSprite;
	private var _opName:flixel.text.FlxBitmapText;
	private var _opState:flixel.text.FlxBitmapText;

	// For both ON | OFF and < > buttons, maybe its bad cuz im bad lol
	private var _op1:OptionInput;
	private var _op2:OptionInput;

	// Real.
	public var data:OptionData;

	// Position
	public var targetY:Float = 0;
	public var yMult:Float = 120;
	public var yAdd:Float = 0;
	public var forceX:Float = Math.NEGATIVE_INFINITY;

	public function new(X:Float, Y:Float, name:String, description:String = '', variable:String = "", type:OptionType = UNKNOWN, defaultVal:Dynamic = null,
			?options:Array<String>, ?bgWidth:Int, ?bgHeight:Int)
	{
		super(X, Y);

		data = new OptionData(name, description, variable, type, defaultVal, options);

		_opName = new flixel.text.FlxBitmapText(base.ui.Fonts.VCR());
		_opName.text = data.name;
		_opName.antialiasing = SaveData.antialiasing;
		base.ui.Fonts.changeFontSize(_opName, 0.6);

		// The same way KeybindSelector makes the bg lol, prob will just use the help text width from keybinds state lmao
		_bg = new flixel.FlxSprite().makeGraphic(bgWidth == null ? Std.int(_opName.width * 1.5) : bgWidth,
			bgHeight == null ? Std.int(_opName.height) : bgHeight, flixel.util.FlxColor.BLACK);
		_bg.alpha = 0.5;
		_bg.antialiasing = SaveData.antialiasing;

		if (type == UNKNOWN)
			_opName.x = (_bg.width / 2) - (_opName.width / 2);

		add(_bg);
		add(_opName);

		switch (type)
		{
			case UNKNOWN:
				return;

			case BOOL:
				_op1 = new OptionInput(type, LEFT);
				_op2 = new OptionInput(type, RIGHT);

				_op1.alpha = (data.value ? 1 : 0.5);
				_op2.alpha = (!data.value ? 1 : 0.5);

				_op2.x = ((_bg.x + _bg.width) - _op2.width) - 5;
				_op1.x = _op2.x - _op1.width;

				var posScale:Float = (data.value ? 1 : 0.8);
				var negScale:Float = (!data.value ? 1 : 0.8);
				_op1.scale.set(posScale, posScale);
				_op2.scale.set(negScale, negScale);

				add(_op1);
				add(_op2);

			default:
				_opState = new flixel.text.FlxBitmapText(base.ui.Fonts.VCR());
				_opState.text = data.value;
				_opState.antialiasing = SaveData.antialiasing;
				base.ui.Fonts.changeFontSize(_opState, 0.6);
				_opState.x = ((_bg.x + _bg.width) - _opState.width) - 25;

				add(_opState);

				_op1 = new OptionInput(type, LEFT);
				_op1.trackSpr = _opState;
				_op1.xAdd = -30;
				_op2 = new OptionInput(type, RIGHT);
				_op2.trackSpr = _opState;
				_op2.xAdd = (_opState.width - 15);

				add(_op1);
				add(_op2);
		}
	}

	public function refreshState()
	{
		switch (data.type)
		{
			case UNKNOWN:
				return;

			case BOOL:
				_op1.alpha = (data.value ? 1 : 0.5);
				_op2.alpha = (!data.value ? 1 : 0.5);

				_op2.x = ((_bg.x + _bg.width) - _op2.width) - 5;
				_op1.x = _op2.x - _op1.width;

				var posScale:Float = (data.value ? 1 : 0.8);
				var negScale:Float = (!data.value ? 1 : 0.8);
				_op1.scale.set(posScale, posScale);
				_op2.scale.set(negScale, negScale);

			default:
				convertText();
		}
	}

	public function convertText()
	{
		var text:String = data.displayFormat;
		var val:Dynamic = data.value;
		if (data.type == PERCENT)
			val *= 100;
		var def:Dynamic = data.defaultVal;

		var stringShit:String = text.split("%")[1];
		switch (stringShit)
		{
			case "v":
				_opState.text = StringTools.replace(text, '%v', val);

			case "d":
				_opState.text = StringTools.replace(text, '%d', def);
		}
		_opState.x = ((_bg.x + _bg.width) - _opState.width) - 25;
	}

	// literally copied from keybind selector bruh - gotta fix the inputs they kind of dark
	override public function update(elapsed:Float)
	{
		var fastLerp:Float = funkin.CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		var lerpVal:Float = funkin.CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1);

		var scaledY:Float = flixel.math.FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
		y = flixel.math.FlxMath.lerp(y, (scaledY * yMult) + ((flixel.FlxG.height * 0.5) - (height / 2)) + yAdd, fastLerp);
		if (forceX != Math.NEGATIVE_INFINITY)
			x = flixel.math.FlxMath.lerp(x, forceX, fastLerp);
		else
			x = flixel.math.FlxMath.lerp(x, (targetY * 20) + 90, fastLerp);

		_opName.alpha = flixel.math.FlxMath.lerp(alpha, _opName.alpha, lerpVal);
		if (_opState != null)
			_opState.alpha = flixel.math.FlxMath.lerp(alpha, _opState.alpha, lerpVal);

		_bg.alpha = flixel.math.FlxMath.lerp(alpha * 0.43, _bg.alpha, lerpVal);

		super.update(elapsed);
	}
}

class OptionData
{
	// real shit
	public var value(get, set):Dynamic;
	public var onChange:Void->Void = null;
	public var type:OptionType;

	public var defaultVal:Dynamic = null;
	public var variable:String = "";

	// String based
	public var curOption:Int = 0;
	public var options:Array<String> = null;
	// Non boolean
	public var changeValue:Dynamic = 1;
	public var minValue:Dynamic = null;
	public var maxValue:Dynamic = null;
	public var decimals:Int = 1;

	public var scrollSpeed:Float = 50;

	public var displayFormat:String = '%v';
	public var description:String = '';
	public var name:String = 'Unknown';

	public function new(name:String, description:String = '', variable:String = "", type:OptionType = UNKNOWN, defaultVal:Dynamic = null,
			?options:Array<String>)
	{
		this.name = name;
		this.description = description;
		this.variable = variable;
		this.type = type;
		this.options = options;

		if (defaultVal == null)
		{
			switch (type)
			{
				case UNKNOWN:
					defaultVal = "";

				case BOOL:
					defaultVal = false;
				case INT | FLOAT:
					defaultVal = 0;
				case PERCENT:
					defaultVal = 1;
				case STRING:
					defaultVal = '';
					if (options.length >= 0)
						defaultVal = options[0];
			}
		}

		this.defaultVal = defaultVal;
		if (value == null)
			value = defaultVal;

		switch (type)
		{
			case UNKNOWN | BOOL | INT | FLOAT:
				return;

			case STRING:
				var num:Int = options.indexOf(value);
				if (num > -1)
					curOption = num;

			case PERCENT:
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
		}
	}

	@:noCompletion
	private function get_value()
		return Reflect.field(SaveData, variable);

	@:noCompletion
	private function set_value(value:Dynamic)
	{
		Reflect.setField(SaveData, variable, value);
		return value;
	}

	public function change()
	{
		if (onChange != null)
			onChange();
	}
}

// TODO: Make lil press animation - Could just extend AttachedSprite but nah lol - maybe disable lerping?
class OptionInput extends flixel.FlxSprite
{
	public var trackSpr:flixel.FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public function new(type:OptionType, side:OptionISide = LEFT)
	{
		super();

		switch (type)
		{
			case UNKNOWN:
				return;

			case BOOL:
				loadGraphic(Paths.image('ui/${(side == LEFT) ? "on" : "off"}'));

			case FLOAT | INT | PERCENT | STRING:
				loadGraphic(Paths.image('ui/$side'));
		}

		antialiasing = SaveData.antialiasing;
		scrollFactor.set();
	}

	// bro is filled with flixel.math.FlxMath.lerp :skull:
	override public function update(elapsed:Float)
	{
		if (trackSpr != null)
		{
			var fastLerp:Float = funkin.CoolUtil.boundTo(elapsed * 8.6, 0, 1);

			// One liner would be a mess lol
			x = flixel.math.FlxMath.lerp(x, (trackSpr.x + xAdd), fastLerp);
			y = flixel.math.FlxMath.lerp(y, (trackSpr.y + yAdd), fastLerp);

			// I love lerps
			scrollFactor.x = flixel.math.FlxMath.lerp(scrollFactor.x, trackSpr.scrollFactor.x, fastLerp);
			scrollFactor.y = flixel.math.FlxMath.lerp(scrollFactor.y, trackSpr.scrollFactor.y, fastLerp);

			if (copyAngle)
				angle = flixel.math.FlxMath.lerp(angle, trackSpr.angle + angleAdd, fastLerp);

			if (copyAlpha)
				alpha = flixel.math.FlxMath.lerp(alpha, trackSpr.alpha * alphaMult, fastLerp);

			if (copyVisible)
				visible = trackSpr.visible;
		}

		super.update(elapsed);
	}
}

enum OptionType
{
	BOOL;
	STRING;
	INT;
	FLOAT;
	PERCENT;
	UNKNOWN;
}

// Option Input Side, kind of dumb ik lol, only useful for non boolean options lol
enum abstract OptionISide(String) to String
{
	var LEFT = "left";
	var RIGHT = "right";
}
