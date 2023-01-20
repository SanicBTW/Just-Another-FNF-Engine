package base.pocketbase;

import haxe.Http;
import haxe.Json;
import haxe.io.Bytes;
import openfl.media.Sound;
import openfl.net.URLRequest;

using StringTools;

class Request
{
	public static final base:String = #if html5 "https://pb.sancopublic.tk/api/" #else "http://sancopublic.ddns.net:5430/api/" #end; // im chill like that - its probably unnecessary actually
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

	public static function getSound(collection:String, id:String, file:String, callback:Sound->Void)
	{
		var soundURL:String = base + filesExt.replace(":col", collection).replace(":id", id).replace(":file", file);
		#if html5
		Sound.loadFromFile(soundURL).onComplete(callback);
		#else
		var http = new Http(soundURL);
		http.onBytes = function(data:Bytes)
		{
			var sound = new Sound();
			sound.loadCompressedDataFromByteArray(data, data.length);
			callback(sound);
		}
		http.request();
		#end
	}
}
