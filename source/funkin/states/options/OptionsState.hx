package funkin.states.options;

import base.MusicBeatState;
import base.sprites.RoundSprite;
import base.sprites.StateBG;
import flixel.FlxG;
import flixel.util.FlxColor;
import funkin.components.Sidebar;

class OptionsState extends MusicBeatState
{
	public static var margin:Float = 30;

	private var menuBG:StateBG;
	private var sideBar:Sidebar;
	private var sideContent:RoundSprite;

	private var sections:Array<String> = [
		"Graphics",
		"Gameplay",
		"Optimizations",
		"Gameplay Styling",
		"Timing Windows",
		"Window UI"
	];

	override public function create()
	{
		FlxG.mouse.visible = true;

		menuBG = new StateBG('menuBG');
		add(menuBG);

		var bgOverlay:RoundSprite = new RoundSprite(0, 0, FlxG.width - margin, FlxG.height - margin, [15], FlxColor.BLACK);
		bgOverlay.screenCenter();
		bgOverlay.alpha = 0.5;
		add(bgOverlay);

		sideBar = new Sidebar((bgOverlay.shapeWidth - margin) / 4, bgOverlay.shapeHeight - margin);
		add(sideBar);

		sideContent = new RoundSprite(sideBar.width + (margin / 2), 0, (bgOverlay.width - sideBar.width) - (margin / 2), bgOverlay.shapeHeight - margin, [15],
			FlxColor.WHITE);
		sideContent.screenCenter(Y);
		sideContent.alpha = 0.75;
		add(sideContent);

		for (cat in sections)
		{
			sideBar.addSection(cat, sections[0] == cat, sections[sections.length - 1] == cat);
		}

		super.create();
	}
}
