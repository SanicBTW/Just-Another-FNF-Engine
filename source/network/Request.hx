package network;

import haxe.Exception;
import haxe.Http;
import haxe.io.Bytes;
import openfl.media.Sound;

class Request<T>
{
	public function new(url:String, callback:T->Void, isSound:Bool = false)
	{
		if (isSound)
		{
			// Cuz native is actually gay and won't work with Futures
			#if html5
			Sound.loadFromFile(url).onComplete((sound:Sound) ->
			{
				callback(cast sound);
			});
			#else
			// Look for another way of loading sounds on native
			var req:Http = new Http(url);
			req.onError = (error:String) ->
			{
				throw new Exception('Failed to fetch $url ($error)');
			}
			req.onBytes = (bytes:Bytes) ->
			{
				var sound:Sound = new Sound();
				sound.loadCompressedDataFromByteArray(bytes, bytes.length);
				callback(cast sound);
			}
			req.request();
			#end
		}
		else
		{
			var req:Http = new Http(url);
			req.onError = (error:String) ->
			{
				throw new Exception('Failed to fetch $url ($error)');
			}
			req.onData = (data:String) ->
			{
				// Because most of the responses on HTTP are JSON so will be using generics to give it form and shit
				callback(haxe.Json.parse(data));
			}
			req.request();
		}
	}
}
