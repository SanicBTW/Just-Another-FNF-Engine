package base.server;

import haxe.io.Bytes;
import udprotean.server.UDProteanClientBehavior;

class ServerBehaviour extends UDProteanClientBehavior
{
	override function initialize()
	{
		trace("shits ready");
	}

	// Called after the connection handshake.
	override function onConnect() {}

	override function onMessage(message:Bytes)
	{
		// Repeat all messages back to the client.
		send(message);
	}

	override function onDisconnect() {}
}
