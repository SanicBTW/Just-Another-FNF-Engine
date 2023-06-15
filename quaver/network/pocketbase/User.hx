package network.pocketbase;

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
	var created:String;
	var email:String;
	var emailVisibility:Bool;
	var id:String;
	var name:String;
	var updated:Null<String>;
	var username:String;
	var verified:Bool;
}

typedef UserCredentials =
{
	var identity:String;
	var password:String;
}

// Class that saves login credentials, manages connections and requests

class User
{
	// Why we saving critical data you will ask, just in case it wants a reconnection/refresh of the info object
	@:noCompletion
	private var _credentials:UserCredentials = null;

	@:noCompletion
	// Basically stores the response object
	private var _profile:UserReponse = null;

	public function new(credentials:UserCredentials)
	{
		this._credentials = credentials;

		// Doesn't use my Request class as I'm too lazy to post and shit uhhhhh
		var req:Http = new Http('https://pb.sancopublic.com/api/collections/users/auth-with-password');
		req.addHeader('Content-Type', 'application/json; charset=UTF-8');
		req.setPostData(Json.stringify(credentials));

		req.onData = (raw:String) ->
		{
			this._profile = Json.parse(raw);
			trace(this._profile);
		}

		req.onError = (_) ->
		{
			var parseError:PBRError = Json.parse(req.responseData);
			for (field => sex in parseError.data)
			{
				trace('(${parseError.code}) [$field ${sex.code}]: ${sex.message}');
			}
		}

		// Requires to be a post to get a response
		req.request(true);
	}
}
