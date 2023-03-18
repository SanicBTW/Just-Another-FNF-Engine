package base.system;

#if sys
import sys.thread.Thread;

using StringTools;

class ThreadManager
{
	private static var threadPool:Map<String, Thread> = [];

	public static function setThread(?threadName:String, job:() -> Void)
	{
		var thread:Thread = Thread.create(job);

		if (threadName != null && !threadPool.exists(threadName))
			threadPool.set(threadName, thread);

		if (threadName == null)
		{
			// tm -> Thread Map
			var tmNumber:Int = 0;
			for (tmName in threadPool.keys())
			{
				if (tmName.contains("thread_"))
					tmNumber = Std.parseInt(tmName.split("_")[1]) + 1;
			}
			threadName = 'thread_${tmNumber}';
			threadPool.set(threadName, thread);
		}

		return threadPool.get(threadName);
	}

	public static function removeThread(threadName:String)
	{
		threadPool.remove(threadName);
		trace('Removed ${threadName} from the thread pool');
	}
}
#end
