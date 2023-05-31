package backend;

import sys.thread.Thread;

// Will make more stuff with it but for now gonna keep it basic
class Async
{
	private static var _threads:Array<Thread> = [];
	private static var _threadCycle:Int = 0;

	public static function Initialize(amount:Int = 4)
	{
		for (i in 0...amount)
		{
			_threads.push(Thread.createWithEventLoop(function()
			{
				Thread.current().events.promise();
			}));
		}
	}

	public static function execAsync(func:Void->Void)
	{
		var thread:Thread = _threads[(_threadCycle++) % _threads.length];
		thread.events.run(func);
	}
}
