package network.pocketbase;

import flixel.util.typeLimit.OneOfTwo;
import haxe.DynamicAccess;
import network.AsyncHTTP.RequestType;
import network.pocketbase.Collection;
import network.pocketbase.Record;

using StringTools;

// Just noticed extending Request is kind of dumb, just return a Request lol
class PBRequest<R:Record, C:Collection<R>>
{
	// Thanks to PocketHost for offering the PocketBase Hosting!
	private static final base:String = "https://funky-sanco.pockethost.io/api/";
	private static final recordsExt:String = "collections/:col/records";
	private static final filesExt:String = "files/:col/:id/:file";

	public static function getRecords<R:Record, C:Collection<R>>(collection:String):Request<C>
		return new Request<C>({url: base + recordsExt.replace(":col", collection), type: OBJECT});

	public static function getFile<T, R:Record>(record:R, file:String, type:RequestType):Request<T>
		return new Request<T>({
			url: base + filesExt.replace(":col", record.collectionName).replace(":id", record.id).replace(":file", Reflect.field(record, file)),
			type: type
		});
}

// Error typedef because its related to request error lol
typedef PBRError = // PocketBase Request Error
{
	var code:OneOfTwo<Int, String>;
	var message:String;
	@:optional var data:DynamicAccess<PBRError>;
}
