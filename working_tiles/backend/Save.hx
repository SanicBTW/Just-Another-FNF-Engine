package backend;

import lime.app.Application;
#if html5
import js.Browser;
import js.html.idb.*;
#end

class Save
{
	#if html5
	// I don't fucking now how does this work lol
	// https://developer.mozilla.org/es/docs/Web/API/IDBObjectStore
	private static var _dbRequest:OpenDBRequest;
	private static var _db:Database;

	public static function Initialize()
	{
		_dbRequest = Browser.window.indexedDB.open("funkin", Std.parseInt(Application.current.meta.get("version").split(".")[1]));

		_dbRequest.addEventListener('error', () ->
		{
			trace('Error loading database (${_dbRequest.error})');
		});

		_dbRequest.addEventListener('success', () ->
		{
			_db = _dbRequest.result;
		});

		_dbRequest.addEventListener('upgradeended', (ev) ->
		{
			_db = ev.target.result;
			_db.addEventListener('error', (ev) ->
			{
				trace('Error loading database (${ev})');
			});

			var objectStore:ObjectStore = _db.createObjectStore("settings", {keyPath: 'option'});
			objectStore.createIndex("value", "value", {unique: false});

			trace('Created object store');
		});
	}
	#else
	public static function Initialize() {}
	#end
}
