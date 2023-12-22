package network;

import backend.Cache;
import backend.SPromise;
import com.akifox.asynchttp.*;
import flixel.graphics.FlxGraphic;
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

// Dumb fr
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

class Request<T> extends SPromise<T>
{
	public static var userAgent:String = 'JAFE 0.2.10'; // See README.md Versioning

	public function new(opt:RequestOptions)
	{
		super((resolve, reject) ->
		{
			var http = new HttpRequest({
				url: opt.url,
				async: true,
				headers: new HttpHeaders(),
				callback: (response:HttpResponse) ->
				{
					if (!response.isOK)
					{
						reject(response.status);
						return;
					}

					switch (opt.type)
					{
						case STRING:
							resolve(cast response.content);

						case OBJECT:
							resolve(cast haxe.Json.parse(response.content));

						case BYTES:
							resolve(cast response.contentRaw);

						case SOUND:
							if (Cache.exists(opt.url))
							{
								resolve(cast Cache.get(opt.url, SOUND));
								return;
							}

							#if html5
							Sound.loadFromFile(opt.url).onComplete((sound:Sound) ->
							{
								resolve(cast Cache.set(sound, SOUND, opt.url));
							});
							#else
							var sound:Sound = new Sound();
							sound.loadCompressedDataFromByteArray(response.contentRaw, response.contentRaw.length);
							resolve(cast Cache.set(sound, SOUND, opt.url));
							#end

						case IMAGE:
							if (Cache.exists(opt.url))
							{
								resolve(cast Cache.get(opt.url, GRAPHIC));
								return;
							}

							#if html5
							Image.loadFromFile(opt.url).onComplete((limeImg:Image) ->
							{
								var bitData:BitmapData = Cache.set(BitmapData.fromImage(limeImg), BITMAP, opt.url);
								var newGraphic:FlxGraphic = Cache.set(FlxGraphic.fromBitmapData(bitData), GRAPHIC, opt.url);

								resolve(cast newGraphic);
							});
							#else
							var limeImg:Image = Image.fromBytes(response.contentRaw);
							var bitData:BitmapData = Cache.set(BitmapData.fromImage(limeImg), BITMAP, opt.url);
							var newGraphic:FlxGraphic;

							if (Cache.gpuRender)
							{
								var texture:Texture = Cache.getTexture(opt.url, bitData);
								newGraphic = Cache.set(FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture)), GRAPHIC, opt.url);
							}
							else
								newGraphic = Cache.set(FlxGraphic.fromBitmapData(bitData), GRAPHIC, opt.url);

							resolve(cast newGraphic);
							#end
					}
				},
				callbackError: (response:HttpResponse) ->
				{
					reject(response.error);
				},
				callbackProgress: (loaded:Int, total:Int) -> {}
			});

			if (opt.headers != null)
			{
				for (header in opt.headers)
				{
					http.headers.add(header.name, header.value);
				}
			}

			// Refused to set unsafe header "User-Agent"
			#if !html5 http.headers.add('User-Agent', userAgent); #end

			/*
				// http-socket doesnt have posting
				if (opt.post != null && opt.post)
				{
					if (opt.postData != null)
						http.setPostData(opt.postData);
					if (opt.postBytes != null)
						http.setPostBytes(opt.postBytes);
			}*/

			#if html5
			if (opt.type != SOUND || opt.type != IMAGE)
				http.send();
			#else
			http.send();
			#end
		});
	}
}
