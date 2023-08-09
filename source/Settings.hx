package;

class Settings
{
	// Graphics
	public static var antialiasing:Bool = true;

	// Optimizations
	public static var showNoteSplashes:Bool = false;
	public static var comboStacking:Bool = true;

	// Timings & Accuracy styles
	public static var ratingStyle:funkin.Timings.RatingStyle = PSYCH;
	public static var accuracyStyle:funkin.Timings.AccuracyStyle = SCORE;

	// Timing Windows
	public static var sickTiming:Float = 45;
	public static var goodTiming:Float = 90;
	public static var badTiming:Float = 135;
	public static var shitTiming:Float = 166;
	public static var missTiming:Float = 180;
}
