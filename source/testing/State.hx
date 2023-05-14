package testing;

import backend.Cache;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import network.Request;
import network.pocketbase.Collection;
import network.pocketbase.Record;
import openfl.media.Sound;

class State extends FlxState
{
	override public function create()
	{
		new Request<Collection<FunkinRecord>>("https://pb.sancopublic.com/api/collections/funkin/records/", (shit) ->
		{
			trace(shit);
		});

		super.create();
	}
}
