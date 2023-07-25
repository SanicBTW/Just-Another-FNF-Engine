package network;

import backend.BackgroundThread;
import backend.Cache;
import backend.Event;
import flixel.graphics.FlxGraphic;
import haxe.Http;
import haxe.io.Bytes;
import lime.graphics.Image;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;

typedef RequestOptions =
{
	var url:String;
	var type:RequestType;

	// headerss
	var ?headers:Array<RequestHeader>;
	// post shit
	var ?post:Bool;
	var ?postData:Null<String>;
	var ?postBytes:Null<Bytes>;
}

// Dumbfr
typedef RequestHeader =
{
	var name:String;
	var value:String;
}

enum RequestType
{
	STRING;
	OBJECT;
	BYTES;
	SOUND;
	IMAGE;
}

// Rewritten again
// Extends Event for instant event listening
class Request<T> extends Event<T>
{
	public static var userAgent:String = 'JAFE 0.2.10'; // See README.md Versioning

	override public function new(opt:RequestOptions)
	{
		super('NetRequest:${opt.url}');

		var http:Http = new Http(opt.url);

		if (opt.headers != null)
		{
			for (header in opt.headers)
			{
				http.addHeader(header.name, header.value);
			}
		}

		// Refused to set unsafe header "User-Agent"
		#if !html5 http.addHeader('User-Agent', userAgent); #end

		http.onError = (msg) ->
		{
			var error = http.responseData == null ? msg : http.responseData;
			dispatch(cast error);
			return;
		}

		switch (opt.type)
		{
			case STRING:
				http.onData = (data:String) ->
				{
					dispatch(cast data);
				}

			case OBJECT:
				http.onData = (data:String) ->
				{
					dispatch(cast haxe.Json.parse(data));
				}

			case BYTES:
				http.onBytes = (bytes:Bytes) ->
				{
					dispatch(cast bytes);
				}

			case SOUND:
				#if html5
				Sound.loadFromFile(opt.url).onComplete((sound:Sound) ->
				{
					dispatch(cast Cache.set(sound, SOUND, opt.url));
				});
				#else
				http.onBytes = (bytes:Bytes) ->
				{
					var sound:Sound = new Sound();
					sound.loadCompressedDataFromByteArray(bytes, bytes.length);
					dispatch(cast Cache.set(sound, SOUND, opt.url));
				}
				#end

			case IMAGE:
				#if html5
				Image.loadFromFile(opt.url).onComplete((limeImg:Image) ->
				{
					var bitData:BitmapData = Cache.set(BitmapData.fromImage(limeImg), BITMAP, opt.url);
					var newGraphic:FlxGraphic = Cache.set(FlxGraphic.fromBitmapData(bitData), GRAPHIC, opt.url);

					dispatch(cast newGraphic);
				});
				#else
				http.onBytes = (bytes:Bytes) ->
				{
					var limeImg:Image = Image.fromBytes(bytes);
					var bitData:BitmapData = Cache.set(BitmapData.fromImage(limeImg), BITMAP, opt.url);
					var newGraphic:FlxGraphic;

					if (Cache.gpuRender)
					{
						var texture:Texture = Cache.getTexture(opt.url, bitData);
						newGraphic = Cache.set(FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture)), GRAPHIC, opt.url);
					}
					else
						newGraphic = Cache.set(FlxGraphic.fromBitmapData(bitData), GRAPHIC, opt.url);

					dispatch(cast newGraphic);
				}
				#end
		}

		if (opt.post != null && opt.post)
		{
			if (opt.postData != null)
				http.setPostData(opt.postData);
			if (opt.postBytes != null)
				http.setPostBytes(opt.postBytes);
		}

		#if html5
		if (opt.type != SOUND || opt.type != IMAGE)
			http.request(opt.post);
		#else
		BackgroundThread.execute(() ->
		{
			try
			{
				http.request(opt.post);
			}
			catch (ex)
			{
				trace(ex);
			}
		});
		#end
	}
}
