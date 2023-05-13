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
		new Request<Sound>("https://pb.sancopublic.com/api/files/9id75c79c70m6yq/g68gjclnsjb60ev/inst_l65pmWJN9z.ogg", (shitsound) ->
		{
			FlxG.sound.list.add(new FlxSound().loadEmbedded(shitsound, true).play());
		}, true);
		super.create();
	}
}
