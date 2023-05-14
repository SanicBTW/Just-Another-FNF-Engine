package network.pocketbase;

// should get extended as this is the base record
class Record
{
	var id:String;
	var collectionId:String;
	var collectionName:String;
	var created:String;
	var updated:Null<String>;
}

class FunkinRecord extends Record
{
	var song:String;
	var chart:String;
	var inst:String;
	var voices:Null<String>;
}

// Soon...
class JVersionRecord extends Record
{
	var version:String;
	var features:String;
	var payload:String;
	var mode:String;
	var isLatest:Bool;
	var isHotfix:Bool;
}
