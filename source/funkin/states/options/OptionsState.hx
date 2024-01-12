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

	override public function create()
	{
		FlxG.mouse.visible = true;

		menuBG = new StateBG('menuBG');
		add(menuBG);

		var bgOverlay:RoundSprite = new RoundSprite(0, 0, FlxG.width - margin, FlxG.height - margin, [15], FlxColor.BLACK);
		bgOverlay.screenCenter();
		bgOverlay.alpha = 0.5;
		add(bgOverlay);

		add(sideBar = new Sidebar((bgOverlay.shapeWidth - margin) / 4, bgOverlay.shapeHeight - margin));

		super.create();
	}
}
