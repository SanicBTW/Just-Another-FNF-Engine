package quaver;

// Made to store Qua metadata for faster and better reading
// Kind of dumb since only has these methods and nothing else lol
class QuaverDB
{
	public static var loadedMaps:Map<String, Qua> = new Map();
	public static var availableMaps:Map<String, Array<String>> = [
		"24184" => ["107408", "107739", "109360"], // i didn't need you anyway
		"18712" => ["86716", "86717", "86718", "86815", "86816", "86995", "87001", "87536", "93224"], // Lost Umbrella (Cut Ver.)
		"27158" => ["119238", "120078"], // Sonny Boy Rhapsody
		"20163" => ["92090", "92098", "92106", "92337", "92788"], // Daten
		"14049" => ["68238", "68239"], // astrid
		"19079" => ["88035", "93427"], // Wasted (Bootleg Version) (Cut Ver.)
		"21716" => ["97955", "97956"], // LUV U NEED U
		"15833" => ["75104", "75105", "75106", "75107"], // Into Space
	];
}
