package base.system;

#if sys
import sys.thread.Thread;

using StringTools;

// import lime...ThreadPool exxists but dunno if its workin
class ThreadManager
{
	private static var threads:Map<String, Thread> = [];

	public static function setThread(?threadName:String, job:() -> Void)
	{
		var thread:Thread = Thread.create(job);
		trace('Creating thread for $threadName');

		if (threadName != null && !threads.exists(threadName))
			threads.set(threadName, thread);

		if (threadName == null)
		{
			// tm -> Thread Map
			var tmNumber:Int = 0;
			for (tmName in threads.keys())
			{
				if (tmName.contains("thread_"))
					tmNumber = Std.parseInt(tmName.split("_")[1]) + 1;
			}
			threadName = 'thread_${tmNumber}';
			threads.set(threadName, thread);
		}

		return threads.get(threadName);
	}

	public static function removeThread(threadName:String)
	{
		if (!threads.exists(threadName))
		{
			trace('Tried to remove ${threadName} but doesn\'t exist');
			return;
		}

		threads.remove(threadName);
		trace('Removed ${threadName} from the thread map');
	}
}
#else
class ThreadManager
{
	public static function setThread(?threadName:String, job:() -> Void) {}

	public static function removeThread(threadName:String) {}
}
#end
