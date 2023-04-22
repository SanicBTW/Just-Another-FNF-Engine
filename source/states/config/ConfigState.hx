package states.config;

import base.ScriptableState;
import base.system.Controls;
import base.ui.Fonts;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxBitmapText;
import flixel.util.typeLimit.OneOfTwo;
import funkin.Stage;
import states.config.objects.Option.OptionType;
import states.config.objects.Option;

// no reason on extending music beat state if we dont want to use beats and shit
// Using classic Psych Engine settings menu (pre 0.5)
class ConfigState extends ScriptableState
{
	// why not
	private var stage:Stage;

	private var grpOptions:FlxTypedGroup<Option>;
	private var descText:FlxBitmapText;

	private var curSelected(default, set):Int = 0;
	private var curOption(get, null):OptionData;

	private var holdTime:Float = 0;
	private var holdValue:Float = 0;

	// psych way :money_mouth:
	private static var unselectableOptions:Array<String> = ['GRAPHICS', 'GAMEPLAY', 'AUDIO', 'OPTIMIZATION'];

	// easiest way probably
	private static var options:Array<OptionStruct> = [
		{name: 'GRAPHICS'},
		{
			name: "Anti-Aliasing",
			description: 'If disabled, increases performance\nat the cost of the graphics not looking smooth',
			type: BOOL,
			defaultVal: true,
			variable: 'antialiasing'
		},
		#if !html5
		{
			name: 'Framerate',
			description: 'Framerate cap for the application\nDefault: 60',
			type: INT,
			defaultVal: 60,
			variable: 'framerate'
		},
		#end
		{name: 'GAMEPLAY'},
		{
			name: 'Downscroll',
			description: 'If enabled, notes go down instead of up',
			type: BOOL,
			defaultVal: false,
			variable: 'downScroll'
		},
		{
			name: 'Middlescroll',
			description: 'If enabled, centers the note playfield',
			type: BOOL,
			defaultVal: false,
			variable: 'middleScroll'
		},
		{name: 'AUDIO'},
		{
			name: 'Pause Music',
			description: 'The pause menu music',
			type: STRING,
			defaultVal: 'tea-time',
			variable: 'pauseMusic',
			options: ['tea-time', 'breakfast']
		},
		{name: 'OPTIMIZATION'},
		{
			name: 'Only Notes',
			description: 'If enabled, hides everything except the note playfield',
			type: BOOL,
			defaultVal: false,
			variable: 'onlyNotes',
		}
	];

	@:noCompletion
	private function set_curSelected(val:Int):Int
	{
		do
		{
			curSelected += val;

			if (curSelected < 0)
				curSelected = grpOptions.members.length - 1;
			if (curSelected >= grpOptions.members.length)
				curSelected = 0;
		}
		while (unselectableCheck(curSelected));
		descText.text = grpOptions.members[curSelected].data.description;

		var the:Int = 0;

		for (op in grpOptions.members)
		{
			op.targetY = the - curSelected;
			the++;

			if (!unselectableCheck(the - 1))
			{
				op.alpha = 0.4;
				if (op.targetY == 0)
					op.alpha = 0.75;
			}
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));

		return val;
	}

	@:noCompletion
	private function get_curOption():OptionData
	{
		var cur:Option = grpOptions.members[curSelected];
		if (cur != null)
			return cur.data;
		return null;
	}

	override function create()
	{
		stage = new Stage("stage");
		add(stage);

		grpOptions = new FlxTypedGroup<Option>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var data:OptionStruct = options[i];
			var pos:Float = (70 * i) + 30;
			var newOption:Option;
			if (unselectableCheck(i))
				newOption = new Option(0, pos, data.name, "", "", UNKNOWN, null, [], FlxG.width - 30);
			else
				newOption = new Option(0, pos, data.name, data.description, data.variable, data.type, data.defaultVal, data.options, FlxG.width - 30);
			newOption.forceX = 15;
			newOption.yMult = 80;
			newOption.targetY = i;
			grpOptions.add(newOption);
		}

		descText = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(descText, true, 0.55);
		descText.borderSize = 2.4;
		descText.alignment = CENTER;
		descText.setPosition(305, 460);
		add(descText);

		for (i in 0...options.length)
		{
			if (!unselectableCheck(i))
			{
				curSelected = i;
				break;
			}
		}

		super.create();
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		switch (action)
		{
			case "back":
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					SaveData.saveSettings();
					ScriptableState.switchState(new RewriteMenu());
				}

			case "ui_up":
				curSelected = -1;
			case "ui_down":
				curSelected = 1;

			case "reset":
				curOption.value = curOption.defaultVal;
				grpOptions.members[curSelected].refreshState();

			case "confirm":
				if (curOption.type != BOOL)
					return;

				curOption.value = !curOption.value;
				grpOptions.members[curSelected].refreshState();

			case "ui_left" | "ui_right":
				var pressed:Bool = (Controls.isActionPressed("ui_left") || Controls.isActionPressed("ui_right"));
				if (holdTime > 0.5 || pressed)
				{
					if (pressed)
					{
						var add:Dynamic = null;
						if (curOption.type != STRING)
							add = (action == "ui_left" ? -curOption.changeValue : curOption.changeValue);

						switch (curOption.type)
						{
							default:
								{
									holdValue = curOption.value + add;

									if (holdValue < curOption.minValue)
										holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue)
										holdValue = curOption.maxValue;

									switch (curOption.type)
									{
										default:
											return;

										case INT:
											holdValue = Math.round(holdValue);
											curOption.value = holdValue;

										case FLOAT | PERCENT:
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.value = holdValue;
									}
								}

							case STRING:
								{
									var num:Int = curOption.curOption;
									if (action == "ui_left")
										--num;
									else
										num++;

									if (num < 0)
										num = curOption.options.length;
									else if (num >= curOption.options.length)
										num = 0;

									curOption.curOption = num;
									curOption.value = curOption.options[num];
								}
						}
						grpOptions.members[curSelected].refreshState();
					}
					// idk why here we dont set hold value to the parsed value, instead we just put the value of the option to the parsed value
					else if (curOption.type != STRING)
					{
						// this isnt update
						holdValue += curOption.scrollSpeed * FlxG.elapsed * (action == "ui_left" ? -1 : 1);
						if (holdValue < curOption.minValue)
							holdValue = curOption.minValue;
						else if (holdValue > curOption.maxValue)
							holdValue = curOption.maxValue;

						switch (curOption.type)
						{
							default:
								return;

							case INT:
								curOption.value = Math.round(holdValue);

							case FLOAT | PERCENT:
								curOption.value = FlxMath.roundDecimal(holdValue, curOption.decimals);
						}
						grpOptions.members[curSelected].refreshState();
					}
				}
		}
	}

	override public function update(elapsed:Float)
	{
		if ((Controls.isActionPressed("ui_left") || Controls.isActionPressed("ui_right")) && curOption.type != STRING)
			holdTime += elapsed;
		else
			holdTime = 0;

		FlxG.watch.addQuick("shit", holdTime);
		FlxG.watch.addQuick("shit2", holdValue);

		super.update(elapsed);
	}

	// for the uhhhhhhhhhhhhhhhhhhh categories
	private function unselectableCheck(num:Int):Bool
	{
		for (i in 0...unselectableOptions.length)
		{
			if (options[num].name == unselectableOptions[i])
			{
				return true;
			}
		}
		return options[num].name == '';
	}
}

typedef OptionStruct =
{
	var name:String;
	var ?description:String;
	var ?variable:String;
	var ?type:OptionType;
	var ?defaultVal:Dynamic;
	var ?options:Array<String>;
}
