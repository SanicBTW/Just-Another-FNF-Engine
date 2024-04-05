package network;

// https://github.com/SanicBTW/HaxeWS/blob/master/source/plugins/AsyncHTTP.hx - source code not available atm
// https://github.com/SanicBTW/Just-Another-FNF-Engine/blob/f8c33eb84a4aa2858e134820e766bddcf2022332/source/network/Request.hx
// https://github.com/Geokureli/Newgrounds/blob/cd1b2cb1cb71c6b8e6ed27291ea8969009d4e101/lib/Source/io/newgrounds/utils/AsyncHttp.hx
import flixel.FlxBasic;
import flixel.FlxG;
import haxe.Http;
import haxe.io.Bytes;
#if target.threaded
import sys.thread.Thread;

enum abstract HTTPEvents(String) from String to String
{
	var REQUEST_STARTED = "request_started"; // Dispatched when the Request started
	// All of these events pass and object which contain the base request id and the event data
	var REQUEST_FINISHED = "request_finished"; // Dispatched when the Request finishes, passes the finished data, could be a raw string or raw bytes
	var REQUEST_FAILED = "request_failed"; // Dispatched when the Request fails, passes the error
}
#end

typedef RequestOptions =
{
	var url:String;
	var type:RequestType;
	// headerss
	var ?headers:Array<RequestHeader>;
	// post shit
	var ?postData:Null<String>;
	var ?postBytes:Null<Bytes>;
}

typedef RequestCallbacks<T> =
{
	var onSuccess:T->Void;
	var ?onError:Any->Void;
}

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

#if target.threaded
private typedef ThreadMessage =
{
	var opt:RequestOptions;
	var callbacks:RequestCallbacks<Any>;
	var source:Thread;
}

private typedef ResponseMessage =
{
	var event:HTTPEvents;
	var result:Any;
	var callbacks:RequestCallbacks<Any>;
}
#end

// First time making a plugin on Flixel lmfao
class AsyncHTTP extends FlxBasic
{
	public static var instance:AsyncHTTP;

	#if target.threaded
	private var thread:Thread;
	#end

	public function new()
	{
		super();
		#if target.threaded
		thread = Thread.create(sendThreaded);
		#end
		instance = this;
	}

	// Returns the instance of the Plugin for quick accessing to event listeners n shit yknow
	#if target.threaded
	public static function request<T>(opt:RequestOptions, callbacks:RequestCallbacks<T>):AsyncHTTP
	{
		var msg:ThreadMessage = {opt: opt, callbacks: callbacks, source: Thread.current()};
		instance.thread.sendMessage(msg);
		msg = null;
		return instance;
	}

	override function update(elapsed:Float):Void
	{
		var msg:ResponseMessage = cast Thread.readMessage(false);
		if (msg != null)
		{
			switch (msg.event)
			{
				case REQUEST_FINISHED:
					msg.callbacks.onSuccess(msg.result);

				case REQUEST_FAILED:
					if (msg.callbacks.onError != null)
						msg.callbacks.onError(cast msg.result);

				default: // Unreachable
			}

			msg = null;
		}

		super.update(elapsed);
	}

	private function sendThreaded():Void
	{
		while (true)
		{
			var data:ThreadMessage = cast Thread.readMessage(true);
			// hehe
			var handler = (ev) ->
			{
				data.source.sendMessage(ev);
			}
			requestSync(data.opt, data.callbacks, handler, handler);
		}
	}

	private function requestSync(opt:RequestOptions, callbacks:RequestCallbacks<Any>, onFinish:(ResponseMessage->Void), ?onError:(ResponseMessage->Void))
	{
		var http:Http = new Http(opt.url);

		if (opt.headers != null)
		{
			for (header in opt.headers)
			{
				http.addHeader(header.name, header.value);
			}
		}

		if (opt.postData != null)
			http.setPostData(opt.postData);

		if (opt.postBytes != null)
			http.setPostBytes(opt.postBytes);

		http.onError = (msg) ->
		{
			if (onError != null)
			{
				onError({
					event: REQUEST_FAILED,
					result: (http.responseData == null) ? msg : http.responseData,
					callbacks: callbacks
				});
			}
			return;
		}

		http.onData = (rawString) ->
		{
			if (opt.type == BYTES || opt.type == SOUND || opt.type == IMAGE)
				return;

			onFinish({
				event: REQUEST_FINISHED,
				result: rawString,
				callbacks: callbacks
			});
		}

		http.onBytes = (rawBytes) ->
		{
			if (opt.type == STRING || opt.type == OBJECT)
				return;

			onFinish({
				event: REQUEST_FINISHED,
				result: rawBytes,
				callbacks: callbacks
			});
		}

		http.request(opt.postBytes != null || opt.postData != null);
	}
	#else
	public static function request<T>(opt:RequestOptions, callbacks:RequestCallbacks<T>):AsyncHTTP
	{
		var http:Http = new Http(opt.url);

		if (opt.headers != null)
		{
			for (header in opt.headers)
			{
				http.addHeader(header.name, header.value);
			}
		}

		if (opt.postData != null)
			http.setPostData(opt.postData);

		if (opt.postBytes != null)
			http.setPostBytes(opt.postBytes);

		http.onError = (msg) ->
		{
			if (callbacks.onError != null)
				callbacks.onError((http.responseData == null) ? msg : http.responseData);

			return;
		}

		http.onData = (rawString) ->
		{
			if (opt.type == BYTES || opt.type == SOUND || opt.type == IMAGE)
				return;

			callbacks.onSuccess(cast rawString);
		}

		http.onBytes = (rawBytes) ->
		{
			if (opt.type == STRING || opt.type == OBJECT)
				return;

			callbacks.onSuccess(cast rawBytes);
		}

		#if html5
		if (opt.type == SOUND || opt.type == IMAGE)
		{
			// Call onSuccess immediately to be able to execute the Sound/Image loadFromFile function from Request (AsyncHTTP wrapper lmao)
			callbacks.onSuccess(cast "");
			return instance;
		}
		#end

		http.request(opt.postBytes != null || opt.postData != null);

		return instance;
	}
	#end
}
