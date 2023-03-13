package base.system;

import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.Json;
import hx.ws.Types.MessageType;
import hx.ws.WebSocket;

typedef MessageData =
{
	var type:String;
	var content:Null<Array<Dynamic>>;
	var user:String;
}

// aight so apparently native websockets (sys platforms) dont support protocols as js websocket, instead i can just send some data to the server to assign the websocket to the room?
class Websocket
{
	private static var ws(default, null):WebSocket;

	public static var onMessage(default, null):FlxTypedSignal<MessageData->Void> = new FlxTypedSignal<MessageData->Void>();

	// Comp from the ts ws
	private static function parseData(content:String):MessageData
		return Json.parse(content);

	private static function createData(type:String, content:Dynamic, user:String):MessageData
		return {type: type, content: content, user: user};

	public static function init()
	{
		ws = new WebSocket("wss://ws.sancopublic.com", true);
		ws.onerror = function(err)
		{
			trace("SOCKET CLOSED " + err);
			setDetails("Closed connection");
		}
		ws.onopen = function()
		{
			ws.send("Hello world!");
		}
		ws.onmessage = function(message:MessageType)
		{
			switch (message)
			{
				case BytesMessage(content):
					{
						trace("WS Message bytes");
						return;
					}

				case StrMessage(content):
					{
						var parsedContent:MessageData = parseData(content);
						if (parsedContent.type == "server_details")
							setDetails('Uptime (Seconds): ${Math.floor(parsedContent.content[0])}\nMemory: ${parsedContent.content[1]}');

						// Every signal/event listener should handle their own types
						onMessage.dispatch(parsedContent);
					}
			}
		}
	}

	public static function send(x:MessageData)
	{
		ws.send(Json.stringify(x));
	}

	// goofy function
	public static function setDetails(content:String)
	{
		if (Main.socketDetails != null)
			Main.socketDetails.text = 'Socket Info\n${content}';
	}
}
