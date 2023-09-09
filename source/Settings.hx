package;

class Settings
{
	// Graphics
	public static var antialiasing:Bool = true;

	// Gameplay
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var holdLayer:funkin.notes.Note.HoldLayer = TOP_MOST;

	// Optimizations
	public static var showNoteSplashes:Bool = true;

	// Timings & Accuracy styles
	public static var ratingStyle:funkin.Timings.RatingStyle = PSYCH;
	public static var accuracyStyle:funkin.Timings.AccuracyStyle = SCORE;

	// Timing Windows
	public static var sickTiming:Float = 45;
	public static var goodTiming:Float = 90;
	public static var badTiming:Float = 135;
	public static var shitTiming:Float = 166;
	public static var missTiming:Float = 180;

	// Window UI
	public static var designUpdate:window.Overlay.DesignUpdate = UPDATE_3;
}
