package network.pocketbase;

import backend.Immediate;
import flixel.graphics.FlxGraphic;
import haxe.Http;
import haxe.Json;
import network.pocketbase.PBRequest.PBRError;

typedef UserReponse =
{
	var record:UserRecord;
	var token:String;
}

// Just copied fields in order from a response from
// https://pb.sancopublic.com/api/collections/users/auth-with-password
typedef UserRecord =
{
	var avatar:Null<String>;
	var collectionId:String;
	var collectionName:String;
	var created:Date;
	var email:String;
	var emailVisibility:Bool;
	var id:String;
	var name:String;
	var updated:Null<Date>;
	var username:String;
	var verified:Bool;
}

typedef UserCredentials =
{
	var identity:String;
	var password:String;
}

// Class that saves login credentials, manages connections and requests
// Doesn't use my Request Class as it doesn't expose the HTTP instance, will change this soon maybe
// Shitty commets lol

class User
{
	// Why we saving critical data you will ask, just in case it wants a reconnection/refresh of the info object
	@:noCompletion
	private var _credentials:UserCredentials = null;

	@:noCompletion
	// Basically stores the response object
	private var _profile:UserReponse = null;

	// The scheduled functions that will be executed once the main request (constructor) finishes it
	public var schedule:Immediate = new Immediate();

	// If there is a _profile already or if the main request finished successfully
	private var ready:Bool = false;

	// Stores the avatar graphic, useful for scheduled functions
	public var avatar:Null<FlxGraphic> = null;

	public function new(credentials:UserCredentials)
	{
		this._credentials = credentials;

		var req:Http = new Http('https://pb.sancopublic.com/api/collections/users/auth-with-password');
		req.addHeader('Content-Type', 'application/json; charset=UTF-8');

		// Refused to set unsafe header "User-Agent"
		#if !html5 req.addHeader('User-Agent', Request.userAgent); #end
		req.setPostData(Json.stringify(credentials));

		req.onData = (raw:String) ->
		{
			this._profile = Json.parse(raw);
			ready = true;
			schedule.flush();
			trace(this._profile);
		}

		addErrorCb(req);

		// Requires to be a post to get a response
		req.request(true);
	}

	public function getAvatar():Null<FlxGraphic>
	{
		if (!ready)
		{
			// Wacky HTML5 fix
			schedule.push(getAvatar);
			return null;
		}

		var record:UserRecord = _profile.record; // because _profile.record.salkjdlkasjdlkas is really long
		var url:String = 'https://pb.sancopublic.com/api/files/${record.collectionId}/${record.id}/${record.avatar}';

		if (backend.Cache.isCached(url, GRAPHIC))
			return backend.Cache.get(url, GRAPHIC);

		#if html5
		lime.graphics.Image.loadFromFile(url).onComplete((image:lime.graphics.Image) ->
		{
			var bitmap:openfl.display.BitmapData = openfl.display.BitmapData.fromImage(image);
			avatar = backend.Cache.set(FlxGraphic.fromBitmapData(bitmap), GRAPHIC, url);
		});
		#else
		var req:Http = new Http(url);
		req.addHeader('User-Agent', Request.userAgent);

		req.onBytes = (bytes:haxe.io.Bytes) ->
		{
			var image:lime.graphics.Image = lime.graphics.Image.fromBytes(bytes);
			var bitmap:openfl.display.BitmapData = openfl.display.BitmapData.fromImage(image);
			avatar = backend.Cache.set(FlxGraphic.fromBitmapData(bitmap), GRAPHIC, url);
		}

		req.onError = (_) ->
		{
			var parseError:PBRError = Json.parse(req.responseData);
			for (field => sex in parseError.data)
			{
				trace('(${parseError.code}) [${sex.code}] $field: ${sex.message}');
			}
		}

		req.request();
		#end
		schedule.flush();
		return avatar;
	}

	public function refresh()
	{
		if (!ready)
		{
			schedule.push(refresh);
			return;
		}

		// Refreshing!
		ready = false;

		var req:Http = new Http('https://pb.sancopublic.com/api/collections/users/auth-refresh');

		// Refused to set unsafe header "User-Agent"
		#if !html5 req.addHeader('User-Agent', Request.userAgent); #end
		req.addHeader('Authorization', 'Bearer ${_profile.token}');

		req.onData = (raw:String) ->
		{
			this._profile = Json.parse(raw);
			ready = true;
			schedule.flush();
			trace(this._profile);
		}

		addErrorCb(req);

		req.request(true);
	}

	// Helper
	private function addErrorCb(req:Http)
	{
		req.onError = (_) ->
		{
			var parseError:PBRError = Json.parse(req.responseData);
			for (field => sex in parseError.data)
			{
				throw('(${parseError.code}) [${sex.code}] $field: ${sex.message}');
			}
		}
	}
}
