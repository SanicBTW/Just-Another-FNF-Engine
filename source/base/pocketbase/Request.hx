package base.pocketbase;

/*
	#if js
	import js.html.XMLHttpRequest;
	#else
	import haxe.Http;
	#end */
import haxe.Http;
import haxe.Json;

using StringTools;

class Request
{
	public static final base:String = "https://pb.sancopublic.tk/api/";
	public static final recordsExt:String = "collections/:col/records";
	public static final filesExt:String = "files/:col/:id/:file";

	public static function getRecords(collection:String, callback:String->Void)
	{
		var request = new Http(base + recordsExt.replace(":col", collection));
		request.onData = function(data:String)
		{
			callback(data);
		}
		request.request();
	}

	public static function getFile(collection:String, id:String, file:String, callback:String->Void)
	{
		var http = new Http(base + filesExt.replace(":col", collection).replace(":id", id).replace(":file", file));
		http.onData = function(data:String)
		{
			callback(data);
		}
		http.request();
	}

	public static function get(url:String, callback:String->Void)
	{
		var http = new Http(url);
		http.onData = function(data:String)
		{
			callback(data);
		}
		http.request();
	}
}
