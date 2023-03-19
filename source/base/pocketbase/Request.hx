package base.pocketbase;

import base.system.ThreadManager;
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

	public var onSuccess(default, null):FlxTypedSignal<Dynamic->Void> = new FlxTypedSignal<Dynamic->Void>();
	public var onError(default, null):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();
	public var onProgress(default, null):FlxTypedSignal<Float->Void> = new FlxTypedSignal<Float->Void>();

	public function new(url:String, isSound:Bool = false)
	{
		// Only works if the target has system capabilities, if its HTML5 it will run an empty function lol
		#if !html5
		ThreadManager.setThread(url, () -> makeRequest(url, isSound));
		#else
		makeRequest(url, isSound);
		#end
	}

	private function makeRequest(url:String, isSound:Bool)
	{
		#if !html5
		if (url.contains(".mp3"))
			throw new Exception("MP3 is not supported");
		#end

		if (isSound)
		{
			#if html5
			var soundFuture:Future<Sound>;
			soundFuture = Sound.loadFromFile(url);
			soundFuture.onComplete((sound:Sound) ->
			{
				ThreadManager.removeThread(url);
				onSuccess.dispatch(sound);
				soundFuture = null;
			});
			#else
			var sound:Sound = new Sound(new URLRequest(url));

			sound.addEventListener(Event.COMPLETE, (_) ->
			{
				ThreadManager.removeThread(url);
				onSuccess.dispatch(sound);
			});
			#end
		}
		else
		{
			var request:Http = new Http(url);

			request.onError = function(error:String)
			{
				ThreadManager.removeThread(url);
				trace('Error happened while requesting ${url}: ${error}');
				onError.dispatch("Failed to fetch");
			}

			request.onData = function(data:String)
			{
				ThreadManager.removeThread(url);
				onSuccess.dispatch(data);
			}

			request.request();
		}
	}

	public static function getRecords(collection:String)
		return new Request(base + recordsExt.replace(":col", collection));

	public static function getFile(collection:String, id:String, file:String, isSound:Bool = false)
		return new Request(base + filesExt.replace(":col", collection).replace(":id", id).replace(":file", file), isSound);
}
