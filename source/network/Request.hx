package network;

import backend.Cache;
import backend.SPromise;
import flixel.graphics.FlxGraphic;
import haxe.io.Bytes;
import lime.graphics.Image;
import network.AsyncHTTP;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;

class Request<T> extends SPromise<T>
{
	public static var userAgent:String = 'JAFE 1.0.0rc1'; // See README.md Versioning

	public function new(opt:RequestOptions)
	{
		var uaHeader:RequestHeader = {
			name: "User-Agent",
			value: userAgent
		}

		if (opt.headers != null && !opt.headers.contains(uaHeader))
			opt.headers.push(uaHeader);

		if (opt.headers == null)
			opt.headers = [uaHeader];

		super((resolve, reject) ->
		{
			AsyncHTTP.request(opt, {
				onSuccess: (res:Dynamic) ->
				{
					switch (opt.type)
					{
						case STRING | BYTES: resolve(cast res);
						case OBJECT: resolve(cast haxe.Json.parse(res));
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
							var bytes:Bytes = cast res;
							var sound:Sound = new Sound();
							sound.loadCompressedDataFromByteArray(bytes, bytes.length);
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
							var bytes:Bytes = cast res;
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

							resolve(cast newGraphic);
							#end
					}
				},
				onError: (err) ->
				{
					reject(err);
				}
			});
		});
	}
}
