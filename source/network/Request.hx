package network;

import backend.Random;
import haxe.Exception;
#if (!lime_openal || sys)
import haxe.io.Bytes;
import haxe.io.Path;
import lime.system.System;
import soloud.WavStream;
import sys.FileSystem;
import sys.io.File;
#end
#if (lime_openal || js)
import openfl.events.Event;
import openfl.media.Sound;
import openfl.net.URLRequest;
#end
#if js
import js.html.XMLHttpRequest;
#else
import haxe.Http;
#end

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
			// OpenAL support
			#if lime_openal
			// Look for another way of loading sounds on native
			var sound:Sound = new Sound(new URLRequest(url));
			sound.addEventListener(Event.COMPLETE, (_) ->
			{
				callback(cast sound);
			});
			#else
			// Soloud support
			var sound:WavStream = WavStream.create();
			var req:Http = new Http(url);
			req.onError = (error:String) ->
			{
				throw new Exception('Failed to fetch $url ($error)');
			}
			req.onBytes = (bytes:Bytes) ->
			{
				var path:String = Path.join([
					System.applicationStorageDirectory,
					"temp",
					Random.uniqueId() + '.${Path.extension(url)}'
				]);
				if (!FileSystem.exists(Path.directory(path)))
					FileSystem.createDirectory(Path.directory(path));

				File.saveBytes(path, bytes);
				sound.load(path);
				sound.setLooping(true);
				Main.soloud.play(sound);
			}
			req.request();
			#end
			#end
		}
		else
		{
			#if js
			var shit:XMLHttpRequest;
			#else
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
			#end
		}
	}
}
