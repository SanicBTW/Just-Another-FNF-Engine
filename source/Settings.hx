package;

class Settings
{
	// Graphics
	public static var antialiasing:Bool = true;
	public static var bgTheme:Paths.BGTheme = DEFAULT;

	// Gameplay
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var holdLayer:funkin.notes.Note.HoldLayer = IN_FRONT_RECEPTOR;

	// Optimizations
	public static var showNoteSplashes:Bool = true;
	public static var showJudgementCounters:Bool = true;

	// Timings, Accuracy and Diff styles
	public static var ratingStyle:funkin.Judgement.RatingStyle = PSYCH;
	public static var accuracyStyle:funkin.Judgement.AccuracyStyle = SCORE;
	public static var diffStyle:funkin.Judgement.DiffStyle = HITBOX;

	// Timing Windows
	public static var sickTiming:Float = 45;
	public static var goodTiming:Float = 90;
	public static var badTiming:Float = 135;
	public static var shitTiming:Float = 166;
	public static var missTiming:Float = 180;

	// Window UI
	public static var designUpdate:window.Overlay.DesignUpdate = UPDATE_3;
}
