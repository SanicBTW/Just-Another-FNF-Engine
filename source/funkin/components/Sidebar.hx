package funkin.components;

import base.sprites.RoundSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.states.options.OptionsState;

// https://github.com/SanicBTW/FNF-PsychEngine-0.3.2h/blob/a70489586bc1667388f648c008003d975d810670/source/options/SideBar.hx
// TODO - make positions relative to the sprite group current position instead of making them absolute
// Not exactly a component but its used in settings so uhhhh yeah
@:allow(funkin.components.SidebarItem)
class Sidebar extends FlxSpriteGroup
{
	private var _bg:RoundSprite;
	private var _header:FlxText;
	private var _sections:FlxTypedSpriteGroup<SidebarItem>;

	public function new(Width:Float, Height:Float, color:FlxColor = FlxColor.WHITE)
	{
		super();

		_bg = new RoundSprite(0, 0, Width, Height, [15], color);
		_bg.screenCenter();
		_bg.x -= Width + 150; // Margin
		_bg.alpha = 0.75;

		_header = new FlxText(0, 0, 0, "Settings", 32);
		_header.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.BLACK, RIGHT);
		_header.x = ((_bg.x + _header.fieldWidth) / 2) + (_header.size / 2.5); // centered enough??
		_header.y = (_bg.y + _header.fieldHeight) + (OptionsState.margin - 5);

		add(_bg);
		add(_header);
		add(_sections = new FlxTypedSpriteGroup<SidebarItem>());

		#if FLX_DEBUG
		// do not draw the sprite group hitbox but only the sprites in the group
		this.ignoreDrawDebug = true;
		#end
	}

	public function addSection(name:String, isFirst:Bool = false, isEnd:Bool = false)
	{
		if (_sections == null)
			return;

		var section:SidebarItem = new SidebarItem(this, name, isFirst, isEnd);
		if (!isFirst)
		{
			var lastSec:SidebarItem = _sections.members[_sections.length - 1];
			if (lastSec == null)
				return;

			section.y += (lastSec.y + lastSec._bg.shapeHeight);
		}

		_sections.add(section);
	}
}
