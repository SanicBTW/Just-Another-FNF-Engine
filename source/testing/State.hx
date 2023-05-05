package testing;

import flixel.FlxState;
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
			trace(shit.items[0]);
		});
		new Request<Sound>("https://pb.sancopublic.com/api/files/9id75c79c70m6yq/g68gjclnsjb60ev/inst_l65pmWJN9z.ogg", (sound) ->
		{
			sound.play();
		}, true);
		super.create();
	}
}
