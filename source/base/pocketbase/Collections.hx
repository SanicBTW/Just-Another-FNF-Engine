package base.pocketbase;

// Class to save the type definitions of my PocketBase collections
// do a global class to manage collections and stuff not this shit
// to make collections support each other by using a singleton
// Never going to do it apparently lol, I guess I'll do it soon or smth
// soon actually
class PocketBaseObject
{
	public var id:String;
	public var song:String;
	public var chart:String;
	public var inst:String;
	public var voices:String;

	public function new(id:String, song:String, chart:String, inst:String, voices:String)
	{
		this.id = id;
		this.song = song;
		this.chart = chart;
		this.inst = inst;
		this.voices = voices;
	}
}

typedef Funkin =
{
	var id:String;
	var song:String;
	var chart:String;
	var inst:String;
	var voices:String;
}
