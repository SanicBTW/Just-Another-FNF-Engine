package base.pocketbase;

import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.Http;
import openfl.media.Sound;
import openfl.utils.Future;

using StringTools;

#if !html5
import base.system.ThreadManager;
import haxe.io.Bytes;
import openfl.net.URLRequest;
#end

class Request
{
	public static final base:String = "https://pb.sancopublic.com/api/";
	public static final recordsExt:String = "collections/:col/records";
	public static final filesExt:String = "files/:col/:id/:file";

	// The reason the given arg on dispatch is Array<Dynamic> is because it includes the request string (to avoid errors when dispatching and that shit) and the data of the request and stuff
	// Globally used signal for request responses)?
	public static var onSuccess(default, null):FlxTypedSignal<Array<Dynamic>->Void> = new FlxTypedSignal<Array<Dynamic>->Void>();

	// Globally used signal for request errors)?
	public static var onError(default, null):FlxTypedSignal<Array<Dynamic>->Void> = new FlxTypedSignal<Array<Dynamic>->Void>();

	// Globally used signal for request progress)?
	public static var onProgress(default, null):FlxTypedSignal<Array<Dynamic>->Void> = new FlxTypedSignal<Array<Dynamic>->Void>();

	public function new(url:String)
	{
		#if sys
		ThreadManager.setThread('netreq-$url', () -> doRequest(url));
		#else
		doRequest(url);
		#end
	}

	private function doRequest(url:String)
	{
		var request:Http = new Http(url);

		request.onData = function(data:String)
		{
			#if sys
			ThreadManager.removeThread('netreq-$url');
			#end
			onSuccess.dispatch([url, data]);
		}

		request.onError = function(error:String)
		{
			#if sys
			ThreadManager.removeThread('netreq-$url');
			#end

			trace("network request error " + error);
			onError.dispatch([url, "Failed to fetch", error]);
		}

		request.onBytes = function(data:Bytes)
		{
			trace(data.length);
			trace(request.responseBytes.length);
			trace(request.responseData);
		}

		request.request();
	}

	public static function getRecords(collection:String)
	{
		new Request(base + recordsExt.replace(":col", collection));
		return base + recordsExt.replace(":col", collection);
	}

	public static function getFile(collection:String, id:String, file:String)
	{
		new Request(base + filesExt.replace(":col", collection).replace(":id", id).replace(":file", file));
		return base + filesExt.replace(":col", collection).replace(":id", id).replace(":file", file);
	}

	public static function getSound(collection:String, id:String, file:String)
	{
		var soundURL:String = base + filesExt.replace(":col", collection).replace(":id", id).replace(":file", file);

		#if html5
		var soundFuture:Future<Sound>;
		soundFuture = Sound.loadFromFile(soundURL);
		soundFuture.onComplete((sound) ->
		{
			onSuccess.dispatch([soundURL, sound]);
			soundFuture = null;
		});
		soundFuture.onProgress((i1, i2) ->
		{
			trace('$i1/$i2');
		});
		#else
		var sound:Sound = new Sound();

		var http:Http = new Http(soundURL);

		http.onBytes = function(data:Bytes)
		{
			trace(data.length);
			trace(http.responseBytes.length);
			trace(http.responseData);

			ThreadManager.removeThread('netreq-$soundURL');
			sound.loadCompressedDataFromByteArray(data, data.length);
			onSuccess.dispatch([soundURL, sound]);
		}
		http.request();
		#end

		return soundURL;
	}

	public static function clearSignals()
	{
		onSuccess.removeAll();
		onError.removeAll();
		onProgress.removeAll();
	}
}
