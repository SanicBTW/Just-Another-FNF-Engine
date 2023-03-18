package base.pocketbase;

import haxe.Http;
import openfl.media.Sound;

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

	public function new(url:String, callback:String->Void)
	{
		#if sys
		ThreadManager.setThread('netreq-$url', () -> doRequest(url, callback));
		#else
		doRequest(url, callback);
		#end
	}

	private function doRequest(url:String, callback:String->Void)
	{
		var request:Http = new Http(url);

		request.onData = function(data:String)
		{
			#if sys
			ThreadManager.removeThread('netreq-$url');
			#end
			callback(data);
		}

		request.onError = function(error:String)
		{
			#if sys
			ThreadManager.removeThread('netreq-$url');
			#end
			trace("network request error " + error);
			callback("Failed to fetch");
		}

		request.request();
	}

	public static function getRecords(collection:String, callback:String->Void)
		new Request(base + recordsExt.replace(":col", collection), callback);

	public static function getFile(collection:String, id:String, file:String, callback:String->Void)
		new Request(base + filesExt.replace(":col", collection).replace(":id", id).replace(":file", file), callback);

	public static function getSound(collection:String, id:String, file:String, callback:Sound->Void)
	{
		var soundURL:String = base + filesExt.replace(":col", collection).replace(":id", id).replace(":file", file);

		#if html5
		Sound.loadFromFile(soundURL).onComplete((sound) ->
		{
			callback(sound);
		});
		#else
		var sound = new Sound();

		var http = new Http(soundURL);
		http.onBytes = function(data:Bytes)
		{
			#if sys
			ThreadManager.removeThread('netreq-$soundURL');
			#end
			sound.loadCompressedDataFromByteArray(data, data.length);
			callback(sound);
		}
		http.request();
		#end
	}
}
