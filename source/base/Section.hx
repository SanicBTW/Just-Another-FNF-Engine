package base;

typedef SwagSection =
{
	var startTime:Float;
	var endTime:Float;
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Int;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

class Section
{
	public var startTime:Float = 0;
	public var endTime:Float = 0;
	public var sectionNotes:Array<Dynamic> = [];
	public var changeBPM:Bool = false;
	public var bpm:Float = 0;

	public var lengthInSteps:Int = 16;
	public var gfSection:Bool = false;
	public var mustHitSection:Bool = true;

	public function new(lengthInSteps:Int = 16)
	{
		this.lengthInSteps = lengthInSteps;
	}
}
