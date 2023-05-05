package network;

#if js
import js.html.XMLHttpRequest;
#else
import haxe.Http;
#end
import haxe.Exception;
import openfl.media.Sound;

class Request<T>
{
	// Cannot do "if (T is Sound)" cuz little baby will start crying
	private var _url:String;

	public var onError:String->Void;
	public var onSuccess:T->Void;
	public var onProgress:Float->Void;

	public function new(url:String)
	{
		_url = url;

		if (isSound) {}
		else {}
	}

	public function get()
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

	public function getAsSound()
	{
		// Because calling the callback directly will throw an error saying that it wants T instead of Sound
		Reflect.setProperty(this, 'callback', callback);
		// Cuz native is actually gay and won't work with Futures
		#if html5
		Sound.loadFromFile(url).onComplete((sound:Sound) ->
		{
			Reflect.callMethod(this, Reflect.getProperty(this, "callback"), [sound]);
		});
		#else
		// Look for another way of loading sounds on native
		var sound:Sound = new Sound(new URLRequest(url));
		sound.addEventListener(Event.COMPLETE, (_) ->
		{
			Reflect.callMethod(this, Reflect.getProperty(this, "callback"), [sound]);
		});
		#end
	}
}
