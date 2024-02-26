package database;

#if js
import database.IDatabase.DBInitParams;
import database.IDatabase.DatabaseTable;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.ds.DynamicMap;
import js.Browser;
import js.html.idb.*;

using tink.CoreApi;

// Code heavily based off old code and https://github.com/SanicBTW/NEOPlayer/blob/master/src/VFS.hx

/**
 * A string-based key value store using IndexedDB as backend.
 * 
 * This is expected to be thread safe.
 * 
 * @author sanco
 */
class IndexedDBImpl implements IDatabase<IndexedDBImpl>
{
	private var request:OpenDBRequest;
	private var connection:Database;

	private var params:DBInitParams;
	private var connected:Bool = false;

	public function new(params:DBInitParams)
	{
		this.params = params;
	}

	@async public function connect():Promise<IndexedDBImpl>
	{
		if (connected)
			return Promise.resolve(this);

		return new Promise<IndexedDBImpl>((resolve, reject) ->
		{
			request = Browser.window.indexedDB.open(params.path, params.version);

			request.addEventListener('error', () ->
			{
				reject(new Error(InternalError, request.error.message));
			});

			request.addEventListener('blocked', () ->
			{
				reject(new Error(Forbidden, request.error.message));
			});

			// TODO: When upgrading copy the old data and try to move it to the new version of the database
			// Since maybe some users could have an old database version and the newer one has more tables n other stuff, the design would break
			request.addEventListener('upgradeneeded', (ev) ->
			{
				var db:Database = ev.target.result;

				for (table in params.tables)
				{
					if (!db.objectStoreNames.contains(table))
						db.createObjectStore(table);
				}
			});

			request.addEventListener('success', () ->
			{
				connection = request.result;
				connected = true;
				resolve(this);
			});

			return null;
		});
	}

	@async public function set(table:DatabaseTable, key:String, value:Any):Promise<Bool>
	{
		if (!connected)
			return Promise.reject(new Error(InternalError, "Database not connected yet"));

		if (value == null)
			return remove(table, key);

		return new Promise<Bool>((resolve, reject) ->
		{
			var res:Request = connection.transaction(table, READWRITE).objectStore(table).put(preprocessor(value, false), key);

			res.addEventListener('success', () ->
			{
				resolve(true);
			});

			res.addEventListener('error', () ->
			{
				log('Failed to set value in $table for key $key: ${res.error.message}');
				reject(new Error(InternalError, res.error.message));
			});

			return null;
		});
	}

	@async public function remove(table:DatabaseTable, key:String):Promise<Bool>
	{
		if (!connected)
			return Promise.reject(new Error(InternalError, "Database not connected yet"));

		return new Promise<Bool>((resolve, reject) ->
		{
			var res:Request = connection.transaction(table, READWRITE).objectStore(table).delete(key);

			res.addEventListener('success', () ->
			{
				resolve(true);
			});

			res.addEventListener('error', () ->
			{
				log('Failed to remove value in $table for key $key: ${res.error.message}');
				reject(new Error(InternalError, res.error.message));
			});

			return null;
		});
	}

	@async public function get(table:DatabaseTable, key:String):Promise<Any>
	{
		if (!connected)
			return Promise.reject(new Error(InternalError, "Database not connected yet"));

		return new Promise<Any>((resolve, reject) ->
		{
			var res:Request = connection.transaction(table, READWRITE).objectStore(table).get(key);

			res.addEventListener('success', () ->
			{
				if (res.result != null)
					resolve(preprocessor(res.result, true));
				else
					resolve(null);
			});

			res.addEventListener('error', () ->
			{
				log('Failed to get value in $table for key $key: ${res.error.message}');
				reject(new Error(InternalError, res.error.message));
			});

			return null;
		});
	}

	@async public function entries(table:DatabaseTable):Promise<DynamicMap<String, Any>>
	{
		if (!connected)
			return Promise.reject(new Error(InternalError, "Database not connected yet"));

		return new Promise<DynamicMap<String, Any>>((resolve, reject) ->
		{
			var tempMap:DynamicMap<String, Any> = new DynamicMap();
			var length:Int = 0;

			var res:Request = connection.transaction(table, READONLY).objectStore(table).openKeyCursor();

			res.addEventListener('success', () ->
			{
				var cursor:Cursor = res.result;
				if (cursor == null || cursor.source == null)
				{
					tempMap["length"] = length;
					// End of cycling between entries
					resolve(tempMap);
					return;
				}

				var objStr:ObjectStore = cursor.source;
				var obj:Request = objStr.get(cursor.key);
				length++;

				obj.addEventListener('success', () ->
				{
					tempMap[cursor.key] = obj.result;
					cursor.advance(1);
				});
			});

			return null;
		});
	}

	// Internal use only
	public function destroy():Void
	{
		connection.close();
	}

	private function log(v:String)
	{
		#if debug
		trace('IndexedDB Impl > $v');
		#end
	}

	private function preprocessor(v:Any, isGet:Bool):Any
		return (isGet) ? Unserializer.run(v) : Serializer.run(v);
}
#end
