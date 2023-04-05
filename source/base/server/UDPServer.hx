package base.server;

import haxe.io.Bytes;
import sys.thread.Thread;
import udprotean.server.UDProteanServer;

class UDPServer
{
	private static var _server = new UDProteanServer("0.0.0.0", 6543, ServerBehaviour);

	public static function init()
	{
		_server.start();

		Thread.create(() ->
		{
			while (true)
			{
				_server.updateTimeout(0.005);
			}
		});

		_server.stop();
	}
}
