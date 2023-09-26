package network.pocketbase;

import network.pocketbase.Record;

// R means the Record type lol
typedef Collection<R:Record> =
{
	var page:Int;
	var perPage:Int;
	var totalItems:Int;
	var totalPages:Int;
	var items:Array<R>;
}
