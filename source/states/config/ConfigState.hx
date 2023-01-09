package states.config;

import base.SaveData;
import base.ScriptableState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import states.config.ConfigObjects.AlphabetSelector;

// PLANS FOR THE SETTINGS STATE
// make options look centered, fully mouse & keyboard functional, experimental design for alpha builds
// expected design to be = when pressed option tween to center screen then move to another state that has
// the options using the ui buttons on the images folder (the options are an object in order to make it easier aka easier option creation "bool" will use on/off "string/int" will use the arrows)
// will be fully mouse & keyboard functional, layout should be like this
// optName ------spacing----- setter
// description on top???? or below the current option selected???? also make it so when you select and option it sends everything to bg and darkens it with funky tween
class ConfigState extends ScriptableState
{
	private var menuOptions:FlxTypedGroup<AlphabetSelector>;

	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuSDefault'));
		bg.screenCenter();
		bg.color = 0xFFea71fd;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.antialiasing = SaveData.antialiasing;
		add(bg);

		menuOptions = new FlxTypedGroup<AlphabetSelector>();
		add(menuOptions);

		menuOptions.add(new AlphabetSelector("Keybindings"));
	}
}
