package schmovin.interfaces;

// These are here to pass em to Schmovin

typedef ISwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

typedef ISwagSong =
{
	var song:String;
	var notes:Array<ISwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var player1:String;
	var player2:String;
	var validScore:Bool;
}
