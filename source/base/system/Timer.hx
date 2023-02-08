package base.system;

import flixel.FlxBasic;

class Timer extends FlxBasic
{
	private var waitTime:Float = 0;
	private var timerStopped:Bool = false;

	public var timeLeft:Int = 0;

	private var onFinish:Void->Void;
	private var onUpdate:Float->Void;

	public function new(time:Int, onFinish:Void->Void, ?onUpdate:Float->Void)
	{
		super();
		timeLeft = time;
		this.onFinish = onFinish;
		if (onUpdate != null)
			this.onUpdate = onUpdate;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (timerStopped)
			return;

		waitTime += elapsed;
		if (waitTime >= 1)
		{
			waitTime = 0;
			timeLeft--;
		}

		if (onUpdate != null)
			onUpdate(elapsed);

		if (timeLeft <= 0)
		{
			timerStopped = true;
			onFinish();
		}
	}

	public function restart(newTime:Int, ?newFinishCallback:Void->Void, ?newUpdateCallback:Float->Void)
	{
		timeLeft = newTime;
		if (newFinishCallback != null)
			onFinish = newFinishCallback;
		if (newUpdateCallback != null)
			onUpdate = newUpdateCallback;
		waitTime = 0;
		timerStopped = false;
	}
}
