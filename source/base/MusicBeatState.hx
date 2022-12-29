package base;

class MusicBeatState extends ScriptableState implements MusicHandler
{
	/*
		private var lastBeat:Float = 0;
		private var lastStep:Float = 0;

		private var curStep:Int = 0;
		private var curBeat:Int = 0;
		private var curDecimalBeat:Float = 0;
	 */
	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		/*
			if (Conductor.songPosition < 0)
				curDecimalBeat = 0;
			else
			{
				// timing struct shit
				curDecimalBeat = (Conductor.songPosition / 1000) * (Conductor.bpm / 60);
				var nextStep:Int = Math.floor(Conductor.songPosition / Conductor.stepCrochet);
				if (nextStep >= 0)
				{
					if (nextStep > curStep)
					{
						for (i in curStep...nextStep)
						{
							curStep++;
							updateBeat();
							stepHit();
						}
					}
					else if (nextStep < curStep)
					{
						curStep = nextStep;
						updateBeat();
						stepHit();
					}
				}
				Conductor.crochet = ((60 / Conductor.bpm) * 1000);
		}*/
		updateContent(elapsed);
	}

	/*
		private function updateBeat()
		{
			lastBeat = curBeat;
			curBeat = Math.floor(curStep / 4);
		}
	 */
	public function updateContent(elapsed:Float)
	{
		if (Conductor.boundState == this && Conductor.boundSong != null)
			Conductor.updateTimePosition(elapsed);
	}

	public function beatHit() {}

	public function stepHit()
	{
		/*
			if (curStep % 4 == 0)
				beatHit(); */
	}
}

interface MusicHandler
{
	/*
		private var lastBeat:Float;
		private var lastStep:Float;

		private var curStep:Int;
		private var curBeat:Int;
		private var curDecimalBeat:Float; */
	public function updateContent(elapsed:Float):Void;
	public function beatHit():Void;
	public function stepHit():Void;
}
