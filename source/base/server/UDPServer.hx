package base.server;

#if sys
import haxe.io.Bytes;
import udprotean.server.UDProteanServer;

/*
	import js.html.Worker;
	import sys.thread.Thread; */
class UDPServer
{
	private static var _server = new UDProteanServer("0.0.0.0", 6543, ServerBehaviour);

	public static function init()
	{
		_server.start();

		/*
			new Worker();
			Thread.create(() ->
			{
				while (true)
				{
					_server.updateTimeout(0.005);
				}
		});*/

		_server.stop();
	}
}
#end
