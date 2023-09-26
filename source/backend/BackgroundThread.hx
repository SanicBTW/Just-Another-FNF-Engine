package backend;

#if sys
import sys.thread.Thread;

class BackgroundThread
{
	private static var _thread:Thread = Thread.createWithEventLoop(() ->
	{
		Thread.current().events.promise();
	});

	public static function execute(func:Void->Void)
	{
		_thread.events.runPromised(func);
		_thread.events.promise();
	}
}
#else
class BackgroundThread
{
	private static var _thread:Dynamic;

	public static function execute(func:Void->Void) {}
}
#end
