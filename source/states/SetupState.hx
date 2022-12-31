package states;

import base.Cursor;
import base.ScriptableState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class SetupState extends ScriptableState
{
	var sideBarItems:FlxTypedGroup<Item>;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuDefault"));
		bg.screenCenter();
		bg.antialiasing = true;
		bg.alpha = 0.5;
		add(bg);

		var sideBarBG:FlxSprite = new FlxSprite(0, 0).makeGraphic(310, FlxG.height, FlxColor.WHITE);
		sideBarBG.screenCenter(Y);
		sideBarBG.alpha = 0.7;
		sideBarBG.antialiasing = true;
		add(sideBarBG);

		sideBarItems = new FlxTypedGroup();
		add(sideBarItems);

		var item:Item = new Item("Placeholder", 0);
		sideBarItems.add(item);

		var item:Item = new Item("Placeholder", -50);
		sideBarItems.add(item);
		/*
			var curPos:Int = 0;
			for (i in 0...5)
			{
				var item:Item = new Item("Placeholder", curPos - 50);
				sideBarItems.add(item);
				curPos -= 50;
		}*/

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (item in sideBarItems.members)
		{
			if (FlxG.mouse.overlaps(item))
				Cursor.setCursor(HOVER);
			else
				Cursor.setCursor(IDLE);
		}
	}
}

class Item extends FlxSpriteGroup
{
	public var bg:FlxSprite;

	public function new(text:String, y:Float)
	{
		super();

		bg = new FlxSprite().makeGraphic(310, 50, FlxColor.WHITE);
		bg.y -= y;
		bg.alpha = 0.8;
		bg.antialiasing = true;
		add(bg);

		var itemText:FlxText = new FlxText(bg.x + 5, bg.y + 15, 0, text, 20);
		itemText.setFormat("_sans", 20, FlxColor.BLACK, LEFT);
		add(itemText);
	}
}
