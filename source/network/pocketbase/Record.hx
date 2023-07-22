package network.pocketbase;

// Null actually means empty strings lol
typedef Record =
{
	var id:String;
	var collectionId:String;
	var collectionName:String;
	var created:Date;
	var updated:Null<Date>;
}

typedef FunkinRecord =
{
	var id:String;
	var collectionId:String;
	var collectionName:String;
	var created:Date;
	var updated:Null<Date>;

	var song:String;
	var chart:String;
	var inst:String;
	var voices:Null<String>;
}
