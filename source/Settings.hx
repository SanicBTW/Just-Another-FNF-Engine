package;

class Settings
{
	// Saving (yo wtf saving options in a save omg jit trippin)
	public static var saveEncryption:backend.SqliteKeyValue.EncryptionType = NONE;

	// Graphics
	public static var antialiasing:Bool = true;

	// Gameplay
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = true;

	// Optimizations
	public static var simplifyOverlay:Bool = false; // Simplifies the Debug Overlay with some basic TextFields
	public static var simplifyVolumeTray:Bool = false; // Simplifies the Volume Tray with an old version of it (No rounded corners)
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
}
