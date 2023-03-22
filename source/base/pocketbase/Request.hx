package base.pocketbase;

import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.Exception;
import haxe.Http;
import openfl.events.Event;
import openfl.media.Sound;

using StringTools;

#if !html5
import haxe.io.Bytes;
import openfl.net.URLRequest;
#else
import openfl.utils.Future;
#end

class Request
{
	public static final base:String = "https://pb.sancopublic.com/api/";
	public static final recordsExt:String = "collections/:col/records";
	public static final filesExt:String = "files/:col/:id/:file";

	public function new(url:String, isSound:Bool = false, callback:Dynamic->Void)
	{
		if (isSound)
		{
			#if html5
			var soundFuture:Future<Sound>;
			soundFuture = Sound.loadFromFile(url);
			soundFuture.onComplete((sound:Sound) ->
			{
				callback(sound);
				soundFuture = null;
			});
			#else
			if (url.contains(".mp3"))
				throw new Exception("MP3 is not supported");

			var sound:Sound = new Sound(new URLRequest(url));

			sound.addEventListener(Event.COMPLETE, (_) ->
			{
				callback(sound);
			});
			#end
		}
		else
		{
			var request:Http = new Http(url);

			request.onError = function(error:String)
			{
				trace('Error happened while requesting ${url}: ${error}');
				callback('Failed to fetch');
			}

			request.onData = function(data:String)
			{
				callback(data);
			}

			request.request();
		}
	}

	public static function getRecords(collection:String, callback:Dynamic->Void)
		new Request(base + recordsExt.replace(":col", collection), false, callback);

	public static function getFile(collection:String, id:String, file:String, isSound:Bool = false, callback:Dynamic->Void)
		new Request(base + filesExt.replace(":col", collection).replace(":id", id).replace(":file", file), isSound, callback);
}
