package network.pocketbase;

import network.Request.RequestType;
import network.pocketbase.Collection;
import network.pocketbase.Record;

using StringTools;

class PBRequest<R:FunkinRecord, C:Collection<R>> extends Request<C>
{
	private static final base:String = "https://pb.sancopublic.com/api/";
	private static final recordsExt:String = "collections/:col/records";
	private static final filesExt:String = "files/:col/:id/:file";

	override public function new(url:String, callback:C->Void, type:RequestType)
		super(url, callback, type);

	public static function getRecords<R:FunkinRecord, C:Collection<R>>(collection:String, callback:C->Void)
		new PBRequest(base + recordsExt.replace(":col", collection), callback, STRING);

	public static function getFile<R:FunkinRecord, C:Collection<R>>(record:R, file:String, callback:Dynamic->Void, type:RequestType)
		new PBRequest(base + filesExt.replace(":col", record.collectionName).replace(":id", record.id).replace(":file", Reflect.field(record, file)),
			callback, type);
}
