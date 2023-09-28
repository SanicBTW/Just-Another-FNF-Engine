package quaver;

// Made to store Qua metadata for faster and better reading
// Kind of dumb since only has these methods and nothing else lol
// 29/09 Improved loading to get them from existing quaver library and load them first, adding dynamic support and cool shit
class QuaverDB
{
	public static var loadedMaps:Map<String, Qua> = new Map();
	public static var availableMaps:Map<String, Array<String>> = [];
}
