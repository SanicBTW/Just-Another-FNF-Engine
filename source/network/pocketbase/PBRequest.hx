package network.pocketbase;

import flixel.util.typeLimit.OneOfTwo;
import haxe.DynamicAccess;
import network.Request.RequestType;
import network.pocketbase.Collection;
import network.pocketbase.Record;

using StringTools;

class PBRequest<R:Record, C:Collection<R>> extends Request<C>
{
	private static final base:String = "https://pb.sancopublic.com/api/";
	private static final recordsExt:String = "collections/:col/records";
	private static final filesExt:String = "files/:col/:id/:file";

	override public function new(url:String, type:RequestType)
	{
		super({url: url, type: type});
	}

	public static function getRecords<R:Record, C:Collection<R>>(collection:String):PBRequest<R, C>
		return new PBRequest(base + recordsExt.replace(":col", collection), OBJECT);

	public static function getFile<R:Record, C:Collection<R>>(record:R, file:String, type:RequestType):PBRequest<R, C>
		return new PBRequest(base + filesExt.replace(":col", record.collectionName).replace(":id", record.id).replace(":file", Reflect.field(record, file)),
			type);
}

// Error typedef because its related to request error lol
typedef PBRError = // PocketBase Request Error
{
	var code:OneOfTwo<Int, String>;
	var message:String;
	@:optional var data:DynamicAccess<PBRError>;
}
