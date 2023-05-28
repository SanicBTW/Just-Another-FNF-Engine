package network.pocketbase;

// Had to transform everything into a typedef so it doesn't crash when I try to use it
// Duplicate code now :pensive:
typedef Record =
{
	var id:String;
	var collectionId:String;
	var collectionName:String;
	var created:String;
	var updated:Null<String>;
}

typedef FunkinRecord =
{
	var id:String;
	var collectionId:String;
	var collectionName:String;
	var created:String;
	var updated:Null<String>;

	var song:String;
	var chart:String;
	var inst:String;
	var voices:Null<String>;
}

// Soon...
typedef JVersionRecord =
{
	var id:String;
	var collectionId:String;
	var collectionName:String;
	var created:String;
	var updated:Null<String>;

	var version:String;
	var features:String;
	var payload:String;
	var mode:String;
	var isLatest:Bool;
	var isHotfix:Bool;
}
