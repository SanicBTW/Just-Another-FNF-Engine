package network;

import backend.Cache;
import flixel.graphics.FlxGraphic;
import haxe.Http;
import haxe.io.Bytes;
import lime.graphics.Image;
import openfl.display.BitmapData;
import openfl.media.Sound;
#if native
import openfl.display3D.textures.Texture;
#end

// Rewrite soon again (yup yup yup, will add actual threaded good requests ong)
class Request<T>
{
	public static final userAgent:String = 'JAFE 0.2.10X'; // See Notion Versioning

	public function new(url:String, callback:T->Void, type:RequestType)
	{
		var req:Http = new Http(url);

		// Refused to set unsafe header "User-Agent"
		#if !html5 req.addHeader('User-Agent', userAgent); #end

		req.onError = (error:String) ->
		{
			throw('Failed to fetch $url ($error)');
		}

		switch (type)
		{
			// I'm dumb
			case RAW_STRING:
				req.onData = (data:String) ->
				{
					callback(cast data);
				}
			case STRING:
				req.onData = (data:String) ->
				{
					// Because most of the responses on HTTP are JSON so will be using generics to give it form and shit
					callback(cast haxe.Json.parse(data));
				}
			case BYTES:
				req.onBytes = (bytes:Bytes) ->
				{
					callback(cast bytes);
				}
			case SOUND:
				if (Cache.isCached(url, SOUND))
				{
					callback(cast Cache.get(url, SOUND));
					return;
				}

				// Cuz native is actually gay and won't work with Futures
				#if html5
				Sound.loadFromFile(url).onComplete((sound:Sound) ->
				{
					callback(cast Cache.set(sound, SOUND, url));
				});
				#else
				// Look for another way of loading sounds on native
				req.onBytes = (bytes:Bytes) ->
				{
					var sound:Sound = new Sound();
					sound.loadCompressedDataFromByteArray(bytes, bytes.length);
					callback(cast Cache.set(sound, SOUND, url));
				}
				#end
			case IMAGE:
				#if html5
				Image.loadFromFile(url).onComplete((image:Image) ->
				{
					var bitData:BitmapData = BitmapData.fromImage(image);
					var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitData);
					callback(cast newGraphic);
				});
				#else
				// Found out it's probably the easiest way to do it (I guess)
				req.onBytes = (bytes:Bytes) ->
				{
					var limeImg:Image = Image.fromBytes(bytes);
					var bitData:BitmapData = BitmapData.fromImage(limeImg);
					var newGraphic:FlxGraphic;

					if (Cache.gpuRender)
					{
						var texture:Texture = Cache.getTexture(url, bitData);
						newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture));
					}
					else
						newGraphic = FlxGraphic.fromBitmapData(bitData);

					callback(cast newGraphic);
				}
				#end
		}

		#if html5
		// Because native is actually really cool and HTTP Requests with bytes actually work
		if (type != SOUND || type != IMAGE)
			req.request();
		#else
		req.request();
		#end
	}
}

enum RequestType
{
	STRING;
	BYTES;
	SOUND;
	IMAGE;
	RAW_STRING;
}
