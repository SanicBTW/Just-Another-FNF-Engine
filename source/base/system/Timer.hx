package base.system;

import flixel.FlxBasic;

// what
class Timer extends FlxBasic
{
	private var hold:Float = 0;

	public var left:Int = 0;

	private var finish:Void->Void;
	private var stopped:Bool = false;

	public function new(time:Int, finishCallback:Void->Void)
	{
		super();
		this.left = time;
		this.finish = finishCallback;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (stopped)
			return;

		hold += elapsed;
		if (hold >= 1)
		{
			hold = 0;
			left--;
		}

		if (left <= 0)
		{
			stopped = true;
			finish();
		}
	}

	public function restart(newTime:Int, ?newFinishCallback:Void->Void)
	{
		this.left = newTime;
		if (newFinishCallback != null)
			this.finish = newFinishCallback;
		hold = 0;
		stopped = false;
	}
}
