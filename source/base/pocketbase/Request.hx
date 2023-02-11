package base.pocketbase;

import haxe.Http;
import openfl.media.Sound;

using StringTools;

#if !html5
import haxe.io.Bytes;
import openfl.net.URLRequest;
#end

class Request
{
	public static final base:String = "https://pb.sancopublic.tk/api/";
	public static final recordsExt:String = "collections/:col/records";
	public static final filesExt:String = "files/:col/:id/:file";

	public function new(url:String, callback:String->Void)
	{
		var request:Http = new Http(url);

		if (Cache.setNetworkCache(url) != null)
		{
			callback(Cache.setNetworkCache(url));
			return;
		}

		request.onData = function(data:String)
		{
			Cache.setNetworkCache(url, data);
			callback(data);
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
		if (Cache.setNetworkCache(soundURL) != null)
		{
			callback(Cache.setNetworkCache(soundURL));
			return;
		}

		Sound.loadFromFile(soundURL).onComplete((sound) ->
		{
			Cache.setNetworkCache(soundURL, sound);
			callback(sound);
		});
		#else
		var sound = new Sound();

		if (Cache.setNetworkCache(soundURL) != null)
		{
			sound.loadCompressedDataFromByteArray(Cache.setNetworkCache(soundURL), Cache.setNetworkCache(soundURL).length);
			callback(sound);
			return;
		}

		var http = new Http(soundURL);
		http.onBytes = function(data:Bytes)
		{
			Cache.setNetworkCache(soundURL, data);
			sound.loadCompressedDataFromByteArray(data, data.length);
			callback(sound);
		}
		http.request();
		#end
	}
}
